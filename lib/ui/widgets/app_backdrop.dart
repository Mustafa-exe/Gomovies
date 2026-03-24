import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1117),
                Color(0xFF131A24),
                Color(0xFF0E151F),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _GlowOrb(size: 280, color: const Color(0x3321D4FD)),
        ),
        Positioned(
          bottom: -140,
          left: -110,
          child: _GlowOrb(size: 320, color: const Color(0x33F9A826)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoiseLinesPainter(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

class _NoiseLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x11FFFFFF)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 14) {
      final wave = math.sin(y / 18) * 8;
      canvas.drawLine(Offset(wave, y), Offset(size.width + wave, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
