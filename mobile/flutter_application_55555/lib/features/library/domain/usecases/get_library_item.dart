import '../entities/library_item.dart';
import '../repositories/library_repository.dart' as repo_interface;

class GetLibraryItem {
  final repo_interface.LibraryRepository repository;

  GetLibraryItem(this.repository);

  Future<LibraryItem?> call(String id) => repository.fetchItem(id);
}
