import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';
import '../repositories/library_repository.dart' as repo_interface;

class GetLibraryCategories {
  final repo_interface.LibraryRepository repository;

  GetLibraryCategories(this.repository);

  Future<List<LibraryCategory>> call() => repository.fetchCategories();
}
