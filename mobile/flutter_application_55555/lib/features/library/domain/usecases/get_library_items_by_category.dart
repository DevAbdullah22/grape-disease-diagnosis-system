import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import '../repositories/library_repository.dart' as repo_interface;

class GetLibraryItemsByCategory {
  final repo_interface.LibraryRepository repository;

  GetLibraryItemsByCategory(this.repository);

  Future<List<LibraryItem>> call(String categoryId) =>
      repository.fetchItemsByCategory(categoryId);
}
