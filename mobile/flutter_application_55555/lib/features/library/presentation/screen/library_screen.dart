import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/app/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_55555/features/library/domain/entities/library_category.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_categories.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_favorites.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items_by_category.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/toggle_library_favorite.dart';

import '../cubit/library_cubit.dart';
import '../widgets/library_image_placeholder.dart';
import 'library_item_details_screen.dart';

/// شاشة المكتبة الزراعية - تصميم متجاوب ودعم العربية وحالات التحميل والأخطاء
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final LibraryCubit _cubit;
  late int _myTabIndex;

  // controller and current query for the search bar.  The previous design
  // rendered a non-functional placeholder; the TextField below lets the user
  // type and filters the list of items in place.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';  // trimmed, lowercase

  @override
  void initState() {
    super.initState();
    _cubit = LibraryCubit(
      getLibraryCategories: context.read<GetLibraryCategories>(),
      getLibraryItems: context.read<GetLibraryItems>(),
      getLibraryItemsByCategory: context.read<GetLibraryItemsByCategory>(),
      getLibraryFavorites: context.read<GetLibraryFavorites>(),
      toggleLibraryFavorite: context.read<ToggleLibraryFavorite>(),
      resolveLibraryImageUrl: context.read<ResolveLibraryImageUrl>(),
    );
    _cubit.initialize();

    // listen for main navigation changes so that we can refresh favorites
    // when the library tab becomes visible.  This mirrors the behavior in the
    // home screen where favorites are reloaded on tab activation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myTabIndex = Directionality.of(context) == TextDirection.rtl ? 1 : 2;
      mainNavController.addListener(_onNavChanged);
    });
  }

  @override
  void dispose() {
    try {
      mainNavController.removeListener(_onNavChanged);
    } catch (_) {}
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _selectCategory(String id) {
    // reset search whenever the user chooses a different category so that
    // filtering starts fresh for the new set of items.
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    }
    _cubit.selectCategory(id);
  }

  void _onNavChanged() {
    if (!mounted) return;
    if (mainNavController.index == _myTabIndex) {
      // user has switched to the library tab; favorites might have changed
      _cubit.refreshFavorites();
    }
  }

  Future<List<LibraryItem>>? get _futureItems => _cubit.state.futureItems;
  List<LibraryCategory> get _categories => _cubit.state.categories;
  String get _selectedCategoryId => _cubit.state.selectedCategoryId;
  Set<String> get _favorites => _cubit.state.favorites;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LibraryCubit>.value(
      value: _cubit,
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: const Color(0xFFF0F4F8),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildCategoryTabs(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _futureItems == null
                            ? const Center(child: CircularProgressIndicator())
                            : FutureBuilder<List<LibraryItem>>(
                                future: _futureItems,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'خطأ عند جلب العناصر: ${snapshot.error}',
                                      ),
                                    );
                                  }
                                  var items = snapshot.data ?? [];
                                  // apply search filter if user typed anything
                                  if (_searchQuery.isNotEmpty) {
                                    items = items
                                        .where((it) => it.title
                                            .toLowerCase()
                                            .contains(_searchQuery))
                                        .toList();
                                  }

                                  if (items.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Text(
                                        _searchQuery.isNotEmpty
                                            ? 'لا توجد نتائج للبحث'
                                            : 'لا توجد مقالات في المكتبة حالياً.',
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 16,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, i) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: _buildLibraryCard(
                                        imageUrl: items[i].imageUrl,
                                        title: items[i].title,
                                        description:
                                            items[i].shortDescription ?? '',
                                        tag:
                                            items[i].categoryName ?? 'غير مصنف',
                                        tagColor: Colors.green,
                                        id: items[i].id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// شريط البحث – الآن تفاعلي
  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        style: const TextStyle(color: Color(0xFF4A5565), fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ابحث في المكتبة الزراعية...',
          prefixIcon: Icon(Icons.search, color: Colors.green.shade600, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// تبويبات التصنيفات
  Widget _buildCategoryTabs() {
    final tabs = <Widget>[];
    tabs.add(
      GestureDetector(
        onTap: () => _selectCategory('all'),
        child: _buildTab('الكل', Colors.green, _selectedCategoryId == 'all'),
      ),
    );

    for (final c in _categories) {
      tabs.add(const SizedBox(width: 8));
      tabs.add(
        GestureDetector(
          onTap: () => _selectCategory(c.id),
          child: _buildTab(c.name, Colors.green, _selectedCategoryId == c.id),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: tabs),
    );
  }

  Widget _buildTab(String label, Color color, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : Colors.white,
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// كارد المكتبة
  Widget _buildLibraryCard({
    required String imageUrl,
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
    String? id,
  }) {
    if (id != null) {
      // ignore: avoid_print
      print('[LibraryScreen] build card id=$id imageUrl=$imageUrl');
    } else {
      // ignore: avoid_print
      print('[LibraryScreen] build card (no id) imageUrl=$imageUrl');
    }

    final finalImageUrl = _cubit.resolveImageUrl(imageUrl);
    // ignore: avoid_print
    print('[LibraryScreen] resolved image url -> $finalImageUrl');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9F8CF)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      if (finalImageUrl.isNotEmpty) {
                        if (finalImageUrl.startsWith('http')) {
                          return Image.network(
                            finalImageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: LibraryImagePlaceholder(
                                  icon: Icons.broken_image,
                                ),
                              );
                            },
                          );
                        } else if (finalImageUrl.startsWith('file://') ||
                            finalImageUrl.startsWith('content://')) {
                          try {
                            final uri = Uri.parse(finalImageUrl);
                            final path = uri.toFilePath();
                            final f = io.File(path);
                            if (f.existsSync()) {
                              return Image.file(
                                f,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            }
                          } catch (_) {}
                          return const SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: LibraryImagePlaceholder(
                              icon: Icons.broken_image,
                            ),
                          );
                        }
                      }
                      return const SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: LibraryImagePlaceholder(),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      if (id == null) return;
                      await _cubit.toggleFavorite(id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _favorites.contains(id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favorites.contains(id)
                            ? Colors.red
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: tagColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5565),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF008236),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFB9F8CF),
                          width: 2,
                        ),
                      ),
                      shadowColor: Colors.green.withOpacity(0.2),
                    ),
                    icon: const Icon(Icons.menu_book, color: Color(0xFF008236)),
                    label: const Text(
                      'اقرأ المزيد',
                      style: TextStyle(
                        color: Color(0xFF008236),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (id == null || id.isEmpty) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LibraryItemDetailsScreen(id: id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
