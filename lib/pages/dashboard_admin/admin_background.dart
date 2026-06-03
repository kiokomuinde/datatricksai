import 'package:flutter/material.dart';

class BackgroundCanvas extends StatelessWidget {
  const BackgroundCanvas({super.key});
  
  @override
  Widget build(BuildContext context) => Positioned.fill(child: CustomPaint(painter: _BgPainter()));
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF020408);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 60) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 60) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}