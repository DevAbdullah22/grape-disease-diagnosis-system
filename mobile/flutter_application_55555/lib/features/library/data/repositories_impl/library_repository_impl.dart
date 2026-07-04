import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';
import 'package:flutter_application_55555/features/library/domain/repositories/library_repository.dart';

import '../datasources/library_image_resolver_datasource.dart';
import '../datasources/library_local_datasource.dart';
import '../datasources/library_remote_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remote;
  final LibraryLocalDataSource local;
  final LibraryImageResolverDataSource imageResolver;

  // Simple in-memory cache to speed up repeated navigations
  final Map<String, List<LibraryItem>> _categoryCache = {};
  List<LibraryItem>? _allCache;
  DateTime? _allCacheTime;

  LibraryRepositoryImpl({
    required this.remote,
    required this.local,
    required this.imageResolver,
  });

  @override
  Future<List<LibraryItem>> fetchItems() async {
    // return cached copy if fetched less than 60 seconds ago
    final now = DateTime.now();
    if (_allCache != null && _allCacheTime != null) {
      final diff = now.difference(_allCacheTime!);
      if (diff.inSeconds < 60) {
        return _allCache!;
      }
    }

    final models = await remote.fetchItems();
    _allCache = models;
    _allCacheTime = now;
    // also populate per-category cache for faster category lookups
    try {
      _categoryCache.clear();
      for (final m in models) {
        final catId = (m.raw['categoryId']?.toString() ?? 'all');
        _categoryCache.putIfAbsent(catId, () => []).add(m);
      }
    } catch (_) {}

    return models;
  }

  @override
  Future<LibraryItem?> fetchItem(String id) async {
    final model = await remote.fetchItem(id);
    return model;
  }

  @override
  Future<List<LibraryItem>> fetchItemsByCategory(String categoryId) async {
    // check category cache first
    if (_categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId]!;
    }

    final models = await remote.fetchItemsByCategory(categoryId);
    _categoryCache[categoryId] = models;
    return models;
  }

  @override
  Future<List<LibraryCategory>> fetchCategories() async {
    final cats = await remote.fetchCategories();
    return cats;
  }

  @override
  Future<Set<String>> getFavoriteItemIds() {
    return local.getFavoriteItemIds();
  }

  @override
  Future<void> saveFavoriteItemIds(Set<String> itemIds) {
    return local.saveFavoriteItemIds(itemIds);
  }

  @override
  String resolveImageUrl(String imageUrl) {
    return imageResolver.resolve(imageUrl);
  }
}
