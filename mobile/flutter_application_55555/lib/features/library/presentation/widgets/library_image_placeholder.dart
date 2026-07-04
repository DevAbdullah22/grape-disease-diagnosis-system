import 'package:flutter/material.dart';

class LibraryImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  const LibraryImagePlaceholder({
    super.key,
    this.icon = Icons.image,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(icon, size: iconSize, color: Colors.grey),
      ),
    );
  }
}
