import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LibraryLocalDataSource {
  Future<Set<String>> getFavoriteItemIds();
  Future<void> saveFavoriteItemIds(Set<String> itemIds);
}

class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  final FirebaseAuth firebaseAuth;

  LibraryLocalDataSourceImpl({required this.firebaseAuth});

  @override
  Future<Set<String>> getFavoriteItemIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesKey();
    final list = prefs.getStringList(key) ?? <String>[];
    return list.toSet();
  }

  @override
  Future<void> saveFavoriteItemIds(Set<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesKey();
    await prefs.setStringList(key, itemIds.toList());
  }

  String _favoritesKey() {
    final uid = firebaseAuth.currentUser?.uid;
    return AppRuntimeContract.libraryFavoritesKey(uid);
  }
}
