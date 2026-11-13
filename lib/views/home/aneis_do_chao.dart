import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MetadeDoChao { tras, frente }

/// Anéis concêntricos desenhados no chão do palco, em duas metades.
class AneisDoChao extends CustomPainter {
  final MetadeDoChao metade;

  const AneisDoChao(this.metade);

  static const _aneis = [(0.74, 26.0), (0.54, 19.0), (0.34, 12.0)];

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = const Color(0xFF6CEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final centro = size.center(Offset.zero);
    // Arco de cima (π → 2π) é o fundo; o de baixo (0 → π) é a frente.
    final inicio = metade == MetadeDoChao.tras ? math.pi : 0.0;

    for (final (largura, altura) in _aneis) {
      final elipse = Rect.fromCenter(
        center: centro,
        width: size.width * largura,
        height: altura,
      );
      canvas.drawArc(elipse, inicio, math.pi, false, tinta);
    }
  }

  @override
  bool shouldRepaint(AneisDoChao antigo) => antigo.metade != metade;
}
