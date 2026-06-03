import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'theme_constants.dart';

// ===========================================================================
// GLASSMORPHISM HELPER COMPONENT
// ===========================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final innerBox = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (kIsWeb ? const Color(0xF2FFFFFF) : glassWhite),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (kIsWeb) {
      return Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: innerBox,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: innerBox,
          ),
        ),
      ),
    );
  }
}