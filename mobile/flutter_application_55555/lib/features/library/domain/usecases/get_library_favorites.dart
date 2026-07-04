import '../repositories/library_repository.dart' as repo_interface;

class GetLibraryFavorites {
  final repo_interface.LibraryRepository repository;

  GetLibraryFavorites(this.repository);

  Future<Set<String>> call() => repository.getFavoriteItemIds();
}
