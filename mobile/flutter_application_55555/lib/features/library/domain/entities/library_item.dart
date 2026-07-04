class LibraryItem {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String sources;
  final String? shortDescription;
  final String? categoryId;
  final String? categoryName;

  LibraryItem({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.sources = '',
    this.shortDescription,
    this.categoryId,
    this.categoryName,
  });

  get createdAt => null;

  get updatedAt => null;
}
