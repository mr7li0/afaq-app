import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An SVG icon widget that automatically mirrors horizontally
/// for RTL locales.
///
/// Directional icons (arrows, chevrons, send) flip based on current locale.
class MirroredIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final bool forceMirror;
  final TextDirection? textDirection;

  const MirroredIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color,
    this.forceMirror = false,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final direction = textDirection ?? Directionality.of(context);
    final shouldMirror = forceMirror || direction == TextDirection.rtl;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(0, 0, shouldMirror ? -1.0 : 1.0),
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
