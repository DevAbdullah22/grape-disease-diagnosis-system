import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_categories.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_favorites.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items_by_category.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/toggle_library_favorite.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final GetLibraryCategories _getLibraryCategories;
  final GetLibraryItems _getLibraryItems;
  final GetLibraryItemsByCategory _getLibraryItemsByCategory;
  final GetLibraryFavorites _getLibraryFavorites;
  final ToggleLibraryFavorite _toggleLibraryFavorite;
  final ResolveLibraryImageUrl _resolveLibraryImageUrl;

  LibraryCubit({
    required GetLibraryCategories getLibraryCategories,
    required GetLibraryItems getLibraryItems,
    required GetLibraryItemsByCategory getLibraryItemsByCategory,
    required GetLibraryFavorites getLibraryFavorites,
    required ToggleLibraryFavorite toggleLibraryFavorite,
    required ResolveLibraryImageUrl resolveLibraryImageUrl,
  }) : _getLibraryCategories = getLibraryCategories,
       _getLibraryItems = getLibraryItems,
       _getLibraryItemsByCategory = getLibraryItemsByCategory,
       _getLibraryFavorites = getLibraryFavorites,
       _toggleLibraryFavorite = toggleLibraryFavorite,
       _resolveLibraryImageUrl = resolveLibraryImageUrl,
       super(const LibraryState.initial());

  Future<void> initialize() async {
    // load cached favorites and initial items/categories
    await _loadFavorites();

    emit(state.copyWith(loading: true));
    try {
      final categories = await _getLibraryCategories();
      final futureItems = _getLibraryItems();
      emit(state.copyWith(categories: categories, futureItems: futureItems));
    } catch (e) {
      emit(
        state.copyWith(
          futureItems: Future<List<LibraryItem>>.error(
            'خدمة المكتبة غير مهيأة: $e',
          ),
        ),
      );
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> selectCategory(String id) async {
    emit(state.copyWith(selectedCategoryId: id, loading: true));
    Future<List<LibraryItem>> futureItems;
    try {
      if (id == 'all') {
        futureItems = _getLibraryItems();
      } else {
        futureItems = _getLibraryItemsByCategory(id);
      }
    } catch (_) {
      futureItems = Future<List<LibraryItem>>.value(<LibraryItem>[]);
    }
    emit(state.copyWith(futureItems: futureItems, loading: false));
  }

  Future<void> toggleFavorite(String itemId) async {
    try {
      final updated = await _toggleLibraryFavorite(
        itemId: itemId,
        currentFavorites: state.favorites,
      );
      emit(state.copyWith(favorites: updated));
    } catch (_) {
      // Keep UI behavior unchanged if persistence fails.
    }
  }

  String resolveImageUrl(String imageUrl) {
    return _resolveLibraryImageUrl(imageUrl);
  }

  /// Public helper to reload favorites from the repository.  This is useful
  /// when another part of the app (for example the home screen) updates the
  /// shared preferences directly and we need to refresh the state to stay in
  /// sync.  Previously favorites were only loaded once during initialization
  /// which caused stale hearts when navigating back to the library tab.
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _getLibraryFavorites();
      emit(state.copyWith(favorites: favorites));
    } catch (_) {
      // Keep UI behavior unchanged if loading favorites fails.
    }
  }
}
