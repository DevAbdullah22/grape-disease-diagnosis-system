import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';

class LibraryItemModel extends LibraryItem {
  final Map<String, dynamic> raw;

  LibraryItemModel({required this.raw})
    : super(
        id: raw['id']?.toString() ?? raw['Id']?.toString() ?? '',
        title: raw['title']?.toString() ?? raw['Title']?.toString() ?? '',
        content: raw['content']?.toString() ?? raw['Content']?.toString() ?? '',
        imageUrl:
            raw['imageUrl']?.toString() ?? raw['ImageUrl']?.toString() ?? '',
        sources: raw['sources']?.toString() ?? raw['Sources']?.toString() ?? '',
        shortDescription:
            raw['shortDescription']?.toString() ??
            raw['ShortDescription']?.toString(),
        categoryId:
            raw['categoryId']?.toString() ??
            raw['CategoryId']?.toString() ??
            (raw['category'] is Map
                ? (raw['category']['id']?.toString())
                : null),
        categoryName:
            raw['categoryName']?.toString() ??
            raw['CategoryName']?.toString() ??
            (raw['category'] is Map
                ? (raw['category']['name'] ?? raw['category']['title'])
                : null),
      );

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    final map = <String, dynamic>{};
    json.forEach((k, v) {
      final key = k.isNotEmpty ? (k[0].toLowerCase() + k.substring(1)) : k;
      map[key] = v;
    });
    return LibraryItemModel(raw: map);
  }
}
