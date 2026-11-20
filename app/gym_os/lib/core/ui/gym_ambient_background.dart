import 'package:flutter/material.dart';

/// A theme-aware ambient background wrapper that provides a neutral dark canvas
/// with a subtle micro-dot texture in Dark Mode (no neon/colored glows), and
/// a clean scaffold background in Light Mode.
class GymAmbientBackground extends StatelessWidget {
  final Widget child;

  const GymAmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Lightweight Micro-Dot Matrix Pattern (subtle, neutral dark)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GymMicroDotPainter(spacing: 24.0, radius: 0.8),
              ),
            ),
          ),

          // Foreground Content
          child,
        ],
      ),
    );
  }
}

/// A lightweight, reusable CustomPainter for drawing subtle micro-dot textures.
class GymMicroDotPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;

  const GymMicroDotPainter({
    this.color = const Color(0x09FFFFFF), // Neutral subtle micro-dots (~3.5% white)
    this.spacing = 24.0,
    this.radius = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GymMicroDotPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
