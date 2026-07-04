import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/service_locator.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/core/services/config.dart';

class HomeFavoritesSection extends StatelessWidget {
  final List<LibraryItem> favoriteItems;
  final VoidCallback onViewAll;
  final void Function(String id) onRemove;
  final void Function(LibraryItem item) onTapItem;

  const HomeFavoritesSection({
    super.key,
    required this.favoriteItems,
    required this.onViewAll,
    required this.onRemove,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final cardWidth = screenW >= 700
        ? 320.0
        : (screenW * 0.72).clamp(220.0, 320.0);
    final cardHeight = 180.0;
    final listHeight = cardHeight + 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'المفضلة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E2939),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'عرض الكل (${favoriteItems.length})',
                style: const TextStyle(color: Color(0xFF008236)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (favoriteItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 56, color: Colors.green.shade200),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد عناصر مفضلة بعد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E2939),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'استكشف المكتبة واحفظ المقالات المهمة هنا لتصلك بسرعة لاحقًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF4A5565)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: onViewAll,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFFCF4),
                      foregroundColor: const Color(0xFF008236),
                      side: const BorderSide(color: Color(0xFF008236)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('تصفح المكتبة', style: TextStyle(color: Color(0xFF008236))),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteItems.length,
              padding: const EdgeInsets.only(right: 0, left: 4),
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = favoriteItems[index];
                return _buildFavoriteCard(
                  context: context,
                  imageUrl: item.imageUrl,
                  title: item.title,
                  tag: item.categoryName,
                  description: item.shortDescription ?? '',
                  id: item.id,
                  width: cardWidth,
                  height: cardHeight,
                  onRemove: () => onRemove(item.id),
                  onTap: () => onTapItem(item),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteCard({
    required BuildContext context,
    required String imageUrl,
    required String title,
    String? tag,
    required String description,
    String? id,
    double width = 220,
    double height = 200,
    VoidCallback? onRemove,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Builder(
                      builder: (context) {
                        final imgH = (height * 0.45).clamp(72.0, height - 60.0);
                        if (imageUrl.contains('figma.com/api/mcp/asset')) {
                          return Image.asset(
                            'assets/leaf.png',
                            height: imgH,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                        String finalImage = imageUrl;
                        final String defaultBase = Config.apiBaseUrl;
                        try {
                          if (imageUrl.startsWith('http')) {
                            finalImage = imageUrl;
                          } else if (imageUrl.startsWith('file://') ||
                              imageUrl.startsWith('content://')) {
                            finalImage = imageUrl;
                          } else if (imageUrl.isNotEmpty) {
                            String base;
                            try {
                              base = locator.get<ApiClient>().baseUrl;
                            } catch (_) {
                              base = defaultBase;
                            }
                            if (imageUrl.startsWith('/')) {
                              finalImage = base.endsWith('/')
                                  ? base.substring(0, base.length - 1) + imageUrl
                                  : base + imageUrl;
                            } else {
                              finalImage = base.endsWith('/') ? base + imageUrl : '$base/$imageUrl';
                            }
                          }
                          if (!(finalImage.startsWith('http') ||
                              finalImage.startsWith('file://') ||
                              finalImage.startsWith('content://'))) {
                            finalImage = '';
                          }
                        } catch (_) {
                          finalImage = '';
                        }

                        if (finalImage.startsWith('http')) {
                          return Image.network(
                            finalImage,
                            height: imgH,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            // fade-in when frame is ready
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: imgH,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: imgH,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          );
                        }
                        if (finalImage.startsWith('file://') || finalImage.startsWith('content://')) {
                          try {
                            final uri = Uri.parse(finalImage);
                            final path = uri.toFilePath();
                            final f = io.File(path);
                            if (f.existsSync()) {
                              return Image.file(
                                f,
                                height: imgH,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 300),
                                    child: child,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: imgH,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              );
                            }
                          } catch (_) {}
                          return Container(
                            height: imgH,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return Container(
                          height: imgH,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tag != null && tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E2939),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () async {
                      // show snackbar with Undo; only call onRemove if user didn't undo
                      final messenger = ScaffoldMessenger.of(context);
                      final controller = messenger.showSnackBar(
                        SnackBar(
                          content: Text('تمت إزالة "$title" من المفضلة'),
                          action: SnackBarAction(label: 'تراجع', onPressed: () {}),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      final reason = await controller.closed;
                      if (reason != SnackBarClosedReason.action) {
                        try {
                          onRemove?.call();
                        } catch (_) {}
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
