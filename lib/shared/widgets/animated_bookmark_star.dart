import 'package:flutter/material.dart';

class AnimatedBookmarkStar extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final double size;

  const AnimatedBookmarkStar({
    super.key,
    this.isActive = false,
    this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isActive ? Icons.star : Icons.star_border,
        size: size,
        color: isActive ? Colors.amber : Colors.grey,
      ),
    );
  }
}
