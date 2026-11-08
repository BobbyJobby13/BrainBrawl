import 'package:flutter/material.dart';

import '../../theme/palette.dart';

/// Dark plum backdrop with soft brand-coloured glows and a faint grid.
/// Used behind the landing page and both auth screens.
class GlowBackground extends StatelessWidget {
  const GlowBackground({Key? key, required this.child, this.showGrid = true})
      : super(key: key);

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Palette.background)),
        const Positioned(
          top: -200,
          left: -150,
          child: _Glow(size: 540, color: Palette.pink),
        ),
        const Positioned(
          top: 80,
          right: -190,
          child: _Glow(size: 600, color: Palette.violet),
        ),
        const Positioned(
          bottom: -260,
          left: 80,
          child: _Glow(size: 560, color: Palette.cyan),
        ),
        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.20), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    const double step = 72;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
