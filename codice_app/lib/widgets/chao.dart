import 'package:flutter/material.dart';
import 'dart:math' as math;

enum MetadeDoChao { tras, frente }

class GroundCirclesPainter extends CustomPainter {
  final MetadeDoChao metade;

  const GroundCirclesPainter({required this.metade});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6CEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final centro = Offset(size.width / 2, size.height / 2);

    // Arco de cima (π → 2π) é o fundo; o de baixo (0 → π) é a frente.
    final inicio = metade == MetadeDoChao.tras ? math.pi : 0.0;

    // Largura em fração do palco, altura fixa: anéis concêntricos.
    const aneis = [(0.74, 26.0), (0.54, 19.0), (0.34, 12.0)];
    for (final (largura, altura) in aneis) {
      canvas.drawArc(
        Rect.fromCenter(
          center: centro,
          width: size.width * largura,
          height: altura,
        ),
        inicio,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GroundCirclesPainter oldDelegate) =>
      oldDelegate.metade != metade;
}
