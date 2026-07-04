import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import '../repositories/library_repository.dart' as repo_interface;

class GetLibraryItems {
  final repo_interface.LibraryRepository repository;

  GetLibraryItems(this.repository);

  Future<List<LibraryItem>> call() => repository.fetchItems();
}
