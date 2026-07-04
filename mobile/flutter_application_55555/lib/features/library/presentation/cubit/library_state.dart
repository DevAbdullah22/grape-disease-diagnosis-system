part of 'library_cubit.dart';

class LibraryState extends Equatable {
  final Future<List<LibraryItem>>? futureItems;
  final List<LibraryCategory> categories;
  final String selectedCategoryId;
  final bool loading;
  final Set<String> favorites;

  const LibraryState({
    required this.futureItems,
    required this.categories,
    required this.selectedCategoryId,
    required this.loading,
    required this.favorites,
  });

  const LibraryState.initial()
    : futureItems = null,
      categories = const <LibraryCategory>[],
      selectedCategoryId = 'all',
      loading = true,
      favorites = const <String>{};

  LibraryState copyWith({
    Future<List<LibraryItem>>? futureItems,
    bool clearFutureItems = false,
    List<LibraryCategory>? categories,
    String? selectedCategoryId,
    bool? loading,
    Set<String>? favorites,
  }) {
    return LibraryState(
      futureItems: clearFutureItems ? null : (futureItems ?? this.futureItems),
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      loading: loading ?? this.loading,
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    categories,
    selectedCategoryId,
    loading,
    favorites,
    futureItems,
  ];
}
