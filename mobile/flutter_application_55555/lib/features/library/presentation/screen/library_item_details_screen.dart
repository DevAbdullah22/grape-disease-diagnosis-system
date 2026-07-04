import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_application_55555/core/widgets/listen_widget.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';

import '../cubit/library_item_details_cubit.dart';
import '../widgets/library_image_placeholder.dart';

class LibraryItemDetailsScreen extends StatefulWidget {
  final String id;
  const LibraryItemDetailsScreen({super.key, required this.id});

  @override
  State<LibraryItemDetailsScreen> createState() =>
      _LibraryItemDetailsScreenState();
}

class _LibraryItemDetailsScreenState extends State<LibraryItemDetailsScreen> {
  late final LibraryItemDetailsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = LibraryItemDetailsCubit(
      getLibraryItem: context.read<GetLibraryItem>(),
      resolveLibraryImageUrl: context.read<ResolveLibraryImageUrl>(),
    );
    _cubit.load(widget.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }

    if (!kIsWeb &&
        (url.startsWith('file://') || url.startsWith('content://'))) {
      try {
        final file = io.File(Uri.parse(url).toFilePath());
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      } catch (_) {}
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return const LibraryImagePlaceholder(iconSize: 64);
  }

  List<Widget> _buildSourceButtons(String sources) {
    final sourceList = sources
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return sourceList.map((url) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () async {
            try {
              await launchUrl(Uri.parse(url));
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('لا يمكن فتح الرابط: $url')),
              );
            }
          },
          icon: const Icon(Icons.link),
          label: Text('مصدر ${sourceList.indexOf(url) + 1}'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            foregroundColor: Colors.green,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<LibraryItemDetailsCubit>.value(
      value: _cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: const Text('تفاصيل المقال'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFFF7F8FA),
            foregroundColor: Colors.black,
          ),
          body: SafeArea(
            top: false,
            child: BlocBuilder<LibraryItemDetailsCubit, LibraryItemDetailsState>(
              builder: (context, state) {
              if (state is LibraryItemDetailsInitial ||
                  state is LibraryItemDetailsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LibraryItemDetailsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل المقال',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'معرف المقال: ${widget.id}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<LibraryItemDetailsCubit>().load(
                            widget.id,
                          );
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final loaded = state as LibraryItemDetailsLoaded;
              final item = loaded.item;
              final imageUrl = loaded.imageUrl;
              final playerTitle = (item.categoryName ?? '').trim().isNotEmpty
                  ? item.categoryName!.trim()
                  : 'الأعراض';

              return Column(
                children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildImage(imageUrl),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFB9F8CF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListenWidget(
                          contentId: item.id,
                          title: item.title,
                          shortDescription: item.shortDescription,
                          markdownContent: item.content,
                          playerTitle: playerTitle,
                          builder: (context, scope) {
                            return Stack(
                              children: [
                                SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                    bottom: scope.extraBottomPadding,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Chip(
                                            label: Text(
                                              (item.categoryName ?? '')
                                                      .trim()
                                                      .isNotEmpty
                                                  ? item.categoryName!.trim()
                                                  : 'غير مصنف',
                                            ),
                                            backgroundColor:
                                                Colors.green.shade50,
                                            side: const BorderSide(
                                              color: Colors.green,
                                            ),
                                          ),
                                          scope.listenButton,
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      scope.buildHighlightedTitle(
                                        theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ) ??
                                            const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (scope.hasShortDescription) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: scope
                                              .buildHighlightedShortDescription(
                                                theme.textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: Colors.black54,
                                                          height: 1.5,
                                                        ) ??
                                                    const TextStyle(
                                                      height: 1.5,
                                                    ),
                                              ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                      Divider(color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      scope.markdownBody,
                                      const SizedBox(height: 24),
                                      if (item.sources.trim().isNotEmpty) ...[
                                        Text(
                                          'المصادر',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        ..._buildSourceButtons(item.sources),
                                      ],
                                    ],
                                  ),
                                ),
                                scope.bottomPlayer,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            ),
          ),
        ),
      ),
    );
  }
}
