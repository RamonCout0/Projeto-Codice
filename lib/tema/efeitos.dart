import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Profundidade do visual: sombras e brilhos reaproveitados pelas telas.
abstract final class Efeitos {
  /// Sombra baixa e suave dos cartões (no escuro ela só "assenta" o cartão).
  static const sombraCartao = [
    BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// Brilho colorido atrás de ícones e do NAVI.
  static List<BoxShadow> brilho(Color cor, {double forca = 0.28, double desfoque = 24}) => [
    BoxShadow(color: cor.withValues(alpha: forca), blurRadius: desfoque),
  ];

  /// Fundo de cartão: um degradê quase imperceptível que dá volume.
  static LinearGradient volume(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(base, Colors.white, 0.04)!, base],
  );

  /// Cartão tingido com a cor de um elemento ou destaque.
  static LinearGradient tingido(Color cor, {double forca = 0.16}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cor.withValues(alpha: forca), Cores.cartao],
  );
}
