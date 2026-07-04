import 'package:flutter/material.dart';

class HomeMainActionsGrid extends StatefulWidget {
  final void Function(String label) onAction;
  final int notificationsCount;

  const HomeMainActionsGrid({
    super.key,
    required this.onAction,
    this.notificationsCount = 0,
  });

  @override
  State<HomeMainActionsGrid> createState() => _HomeMainActionsGridState();
}

class _HomeMainActionsGridState extends State<HomeMainActionsGrid> {
  int _pressedIndex = -1;

  void _onTapDown(int index) {
    setState(() => _pressedIndex = index);
  }

  void _onTapUp(int index, String label) async {
    setState(() => _pressedIndex = -1);
    await Future.delayed(const Duration(milliseconds: 80));
    widget.onAction(label);
  }

  void _onTapCancel() {
    setState(() => _pressedIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      // weight: 2 = primary (most prominent), 1 = prominent, 0 = normal
      {'icon': Icons.camera_enhance_sharp, 'label': 'التشخيص', 'color': Colors.blue, 'weight': 2},
      {'icon': Icons.menu_book, 'label': 'المكتبة', 'color': Colors.green, 'weight': 1},
      {'icon': Icons.history, 'label': 'السجل', 'color': Colors.purple, 'weight': 1},
      {'icon': Icons.notifications_active_outlined, 'label': 'الإشعارات', 'color': Colors.orange, 'weight': 1},
    ];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(items.length, (i) {
        final it = items[i];
        final isNotif = it['label'] == 'الإشعارات';
        return _buildMainCard(
          i,
          it['icon'] as IconData,
          it['label'] as String,
          it['color'] as MaterialColor,
          weight: it['weight'] as int? ?? 0,
          isNotif: isNotif,
        );
      }),
    );
  }

  Widget _buildMainCard(
    int index,
    IconData icon,
    String label,
    MaterialColor color, {
    int weight = 0,
    bool isNotif = false,
  }) {
    // weight: 2 -> primary (diagnosis), 1 -> prominent, 0 -> normal
    final pressed = _pressedIndex == index;
    final scale = pressed ? 0.96 : 1.0;

    final bool isPrimary = weight >= 2;
    final bool isProminent = weight == 1 || isPrimary;
    final double iconSize = isPrimary ? 36 : (isProminent ? 34 : 32);
    final double iconPadding = isPrimary ? 20 : (isProminent ? 18 : 16);
    final double fontSize = isPrimary ? 18 : (isProminent ? 17 : 16);

    final card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPrimary ? 0.07 : 0.05),
              blurRadius: isPrimary ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isProminent ? null : color[100],
                gradient: isProminent
                    ? LinearGradient(colors: [color[200]!, color[400]!])
                    : null,
                borderRadius: BorderRadius.circular(32),
              ),
              padding: EdgeInsets.all(iconPadding),
              child: Icon(icon, color: isProminent ? Colors.white : Colors.green, size: iconSize),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: isProminent ? color[800] : const Color(0xFF1E2939),
              ),
            ),
          ],
        ),
      ),
    );

    // Add badge overlay for notifications (slightly larger, with border)
    Widget finalCard = Stack(
      children: [
        Positioned.fill(child: card),
        if (isNotif && widget.notificationsCount > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Center(
                child: Text(
                  widget.notificationsCount > 99 ? '99+' : widget.notificationsCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTapDown: (_) => _onTapDown(index),
      onTapCancel: _onTapCancel,
      onTapUp: (_) => _onTapUp(index, label),
      child: finalCard,
    );
  }
}
