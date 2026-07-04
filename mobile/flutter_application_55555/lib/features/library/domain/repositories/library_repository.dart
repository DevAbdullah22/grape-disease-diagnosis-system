import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';

abstract class LibraryRepository {
  Future<List<LibraryItem>> fetchItems();
  Future<LibraryItem?> fetchItem(String id);
  Future<List<LibraryItem>> fetchItemsByCategory(String categoryId);
  Future<List<LibraryCategory>> fetchCategories();
  Future<Set<String>> getFavoriteItemIds();
  Future<void> saveFavoriteItemIds(Set<String> itemIds);
  String resolveImageUrl(String imageUrl);
}
