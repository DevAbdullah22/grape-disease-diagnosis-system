import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';

part 'library_item_details_state.dart';

class LibraryItemDetailsCubit extends Cubit<LibraryItemDetailsState> {
  final GetLibraryItem _getLibraryItem;
  final ResolveLibraryImageUrl _resolveLibraryImageUrl;

  LibraryItemDetailsCubit({
    required GetLibraryItem getLibraryItem,
    required ResolveLibraryImageUrl resolveLibraryImageUrl,
  }) : _getLibraryItem = getLibraryItem,
       _resolveLibraryImageUrl = resolveLibraryImageUrl,
       super(LibraryItemDetailsInitial());

  Future<void> load(String id) async {
    emit(LibraryItemDetailsLoading());
    try {
      final item = await _getLibraryItem(id);
      if (item == null) {
        emit(LibraryItemDetailsError());
        return;
      }
      emit(
        LibraryItemDetailsLoaded(
          item: item,
          imageUrl: _resolveLibraryImageUrl(item.imageUrl),
        ),
      );
    } catch (_) {
      emit(LibraryItemDetailsError());
    }
  }
}
