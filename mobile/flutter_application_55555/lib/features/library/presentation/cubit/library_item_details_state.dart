part of 'library_item_details_cubit.dart';

abstract class LibraryItemDetailsState extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class LibraryItemDetailsInitial extends LibraryItemDetailsState {}

class LibraryItemDetailsLoading extends LibraryItemDetailsState {}

class LibraryItemDetailsLoaded extends LibraryItemDetailsState {
  final LibraryItem item;
  final String imageUrl;

  LibraryItemDetailsLoaded({required this.item, required this.imageUrl});

  @override
  List<Object?> get props => <Object?>[item, imageUrl];
}

class LibraryItemDetailsError extends LibraryItemDetailsState {}
