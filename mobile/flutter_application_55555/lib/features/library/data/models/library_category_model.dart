import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';

class LibraryCategoryModel extends LibraryCategory {
  final Map<String, dynamic> raw;

  LibraryCategoryModel({required this.raw})
    : super(
        id: raw['id']?.toString() ?? raw['Id']?.toString() ?? '',
        name: raw['name']?.toString() ?? raw['Name']?.toString() ?? '',
      );

  factory LibraryCategoryModel.fromJson(Map<String, dynamic> json) {
    final map = <String, dynamic>{};
    json.forEach((k, v) {
      final key = k.isNotEmpty ? (k[0].toLowerCase() + k.substring(1)) : k;
      map[key] = v;
    });
    return LibraryCategoryModel(raw: map);
  }
}
