import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter_application_55555/core/network/app_http_client.dart';

import 'package:flutter_application_55555/core/api_client.dart';
import '../models/library_item_model.dart';
import '../models/library_category_model.dart';

class LibraryRemoteDataSource {
  final ApiClient apiClient;
  final AppHttpClient _appHttpClient;

  LibraryRemoteDataSource(this.apiClient)
    : _appHttpClient = AppHttpClient(baseUrl: apiClient.baseUrl);

  Future<List<LibraryItemModel>> fetchItems() async {
    // The backend exposes items per category: GET /api/librarycategory
    // then GET /api/library/category/{categoryId}/items
    final categoriesUri = apiClient.uri('/api/librarycategory');
    final categoriesUriStr = categoriesUri.toString();
    print('[LibraryRemote] GET categories -> $categoriesUriStr');
    final catResp = await _appHttpClient.get(categoriesUri);
    print(
      '[LibraryRemote] categories status=${catResp.statusCode} bodyLen=${catResp.body.length}',
    );
    if (catResp.statusCode != 200) {
      throw Exception(
        'Failed to load library categories: ${catResp.statusCode}',
      );
    }

    // decode categories JSON on background isolate
    final cats = await compute(_decodeJsonList, catResp.body);
    final List<LibraryItemModel> results = [];

    // Fetch items for all categories in parallel to reduce total latency.
    final futures = cats.map((c) async {
      try {
        final Map<String, dynamic> cat = c is Map<String, dynamic>
            ? c
            : Map<String, dynamic>.from(c as Map);
        final id = cat['id']?.toString() ?? cat['Id']?.toString();
        if (id == null || id.isEmpty) return <LibraryItemModel>[];
        final itemsUri = apiClient.uri('/api/library/category/$id/items');
        print('[LibraryRemote] GET items for category $id -> ${itemsUri.toString()}');
        final itemsResp = await _appHttpClient.get(itemsUri);
        print('[LibraryRemote] items status=${itemsResp.statusCode} bodyLen=${itemsResp.body.length}');
        if (itemsResp.statusCode != 200) return <LibraryItemModel>[];

        // decode items JSON on a background isolate
        final list = await compute(_decodeJsonList, itemsResp.body);
        print('[LibraryRemote] items list length=${list.length} for category $id');
        return list
            .where((e) => e != null)
            .map((e) => LibraryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        // ignore individual category failures and continue
        return <LibraryItemModel>[];
      }
    }).toList();

    final lists = await Future.wait(futures);
    for (final l in lists) {
      results.addAll(l);
    }

    return results;
  }

  Future<List<LibraryItemModel>> fetchItemsByCategory(String categoryId) async {
    if (categoryId.isEmpty) return [];
    final itemsUri = apiClient.uri('/api/library/category/$categoryId/items');
    print(
      '[LibraryRemote] GET items for category $categoryId -> ${itemsUri.toString()}',
    );
    final itemsResp = await _appHttpClient.get(itemsUri);
    print(
      '[LibraryRemote] items status=${itemsResp.statusCode} bodyLen=${itemsResp.body.length}',
    );
    if (itemsResp.statusCode != 200) return [];

    final list = await compute(_decodeJsonList, itemsResp.body);
    return list
        .where((e) => e != null)
        .map((e) => LibraryItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<LibraryCategoryModel>> fetchCategories() async {
    final categoriesUri = apiClient.uri('/api/librarycategory');
    print('[LibraryRemote] GET categories -> ${categoriesUri.toString()}');
    final catResp = await _appHttpClient.get(categoriesUri);
    print(
      '[LibraryRemote] categories status=${catResp.statusCode} bodyLen=${catResp.body.length}',
    );
    if (catResp.statusCode != 200) return [];
    final cats = await compute(_decodeJsonList, catResp.body);
    return cats
        .where((e) => e != null)
        .map((e) => LibraryCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LibraryItemModel?> fetchItem(String id) async {
    if (id.isEmpty) return null;
    final uri = apiClient.uri('/api/library/item/$id');
    final resp = await _appHttpClient.get(uri);
    if (resp.statusCode == 200) {
      try {
        final decoded = await compute(_decodeJsonMap, resp.body);
        if (decoded.isNotEmpty) {
          return LibraryItemModel.fromJson(decoded);
        }
      } catch (e) {
        return null;
      }
    }
    // 404 or other statuses
    return null;
  }
}

// top-level helpers for compute
List<dynamic> _decodeJsonList(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
  } catch (_) {}
  return <dynamic>[];
}

Map<String, dynamic> _decodeJsonMap(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return <String, dynamic>{};
}
