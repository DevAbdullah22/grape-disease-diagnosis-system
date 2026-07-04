import '../repositories/library_repository.dart' as repo_interface;

class ToggleLibraryFavorite {
  final repo_interface.LibraryRepository repository;

  ToggleLibraryFavorite(this.repository);

  Future<Set<String>> call({
    required String itemId,
    required Set<String> currentFavorites,
  }) async {
    final updated = <String>{...currentFavorites};
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    await repository.saveFavoriteItemIds(updated);
    return updated;
  }
}
