import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/services/config.dart';

abstract class LibraryImageResolverDataSource {
  String resolve(String imageUrl);
}

class LibraryImageResolverDataSourceImpl
    implements LibraryImageResolverDataSource {
  final ApiClient apiClient;

  LibraryImageResolverDataSourceImpl(this.apiClient);

  @override
  String resolve(String imageUrl) {
    if (imageUrl.isEmpty) {
      return '';
    }

    String finalImageUrl = imageUrl;
    final defaultBase = Config.apiBaseUrl;

    try {
      if (imageUrl.startsWith('http') ||
          imageUrl.startsWith('file://') ||
          imageUrl.startsWith('content://')) {
        finalImageUrl = imageUrl;
      } else {
        String base;
        try {
          base = apiClient.baseUrl;
        } catch (_) {
          base = defaultBase;
        }

        if (imageUrl.startsWith('/')) {
          finalImageUrl = base.endsWith('/')
              ? base.substring(0, base.length - 1) + imageUrl
              : base + imageUrl;
        } else {
          finalImageUrl = base.endsWith('/')
              ? base + imageUrl
              : '$base/$imageUrl';
        }
      }

      if (!(finalImageUrl.startsWith('http') ||
          finalImageUrl.startsWith('file://') ||
          finalImageUrl.startsWith('content://'))) {
        return '';
      }
      return finalImageUrl;
    } catch (_) {
      if (finalImageUrl.startsWith('http') ||
          finalImageUrl.startsWith('file://') ||
          finalImageUrl.startsWith('content://')) {
        return finalImageUrl;
      }
      return '';
    }
  }
}
