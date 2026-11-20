import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Profundidade do visual: sombras e brilhos reaproveitados pelas telas. Os
/// valores acompanham o tema (no escuro a sombra é preta; no claro, um roxo
/// bem suave).
abstract final class Efeitos {
  /// Sombra baixa e suave dos cartões.
  static List<BoxShadow> get sombraCartao => Cores.claro
      ? const [BoxShadow(color: Color(0x143B2D8A), blurRadius: 22, offset: Offset(0, 8))]
      : const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))];

  /// Brilho colorido atrás de ícones e do NAVI.
  static List<BoxShadow> brilho(Color cor, {double forca = 0.28, double desfoque = 24}) => [
    BoxShadow(color: cor.withValues(alpha: Cores.claro ? forca * 0.55 : forca), blurRadius: desfoque),
  ];

  /// Fundo de cartão: um degradê quase imperceptível que dá volume.
  static LinearGradient volume(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: Cores.claro
        ? [base, Color.lerp(base, Cores.roxo, 0.035)!]
        : [Color.lerp(base, Colors.white, 0.045)!, base],
  );

  /// Cartão tingido com a cor de um elemento ou destaque.
  static LinearGradient tingido(Color cor, {double forca = 0.16}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cor.withValues(alpha: Cores.claro ? forca * 0.7 : forca), Cores.cartao],
  );
}
