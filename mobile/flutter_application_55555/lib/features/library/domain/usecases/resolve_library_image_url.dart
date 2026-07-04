import '../repositories/library_repository.dart' as repo_interface;

class ResolveLibraryImageUrl {
  final repo_interface.LibraryRepository repository;

  ResolveLibraryImageUrl(this.repository);

  String call(String imageUrl) => repository.resolveImageUrl(imageUrl);
}
