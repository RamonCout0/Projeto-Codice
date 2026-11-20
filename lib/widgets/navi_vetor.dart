import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/tema/efeitos.dart';

/// A NAVI desenhada em vetor: arte original do projeto, com uma expressão
/// para cada humor e as cores do elemento. É o que aparece quando ainda não
/// há um modelo 3D importado (e funciona em qualquer tela, sem WebView).
class NaviVetor extends StatefulWidget {
  /// Desliga a respiração (os testes de tela usam, para o pumpAndSettle
  /// terminar).
  static bool animacoesAtivas = true;

  final Color cor;
  final Humor humor;
  final double? largura;
  final double? altura;

  /// Se ela flutua suavemente (como se respirasse).
  final bool respirar;

  const NaviVetor({
    super.key,
    required this.cor,
    this.humor = Humor.esperando,
    this.largura,
    this.altura,
    this.respirar = true,
  });

  @override
  State<NaviVetor> createState() => _NaviVetorState();
}

class _NaviVetorState extends State<NaviVetor> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  bool get _anima => widget.respirar && NaviVetor.animacoesAtivas;

  @override
  void initState() {
    super.initState();
    if (_anima) {
      _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arte = SvgPicture.asset(
      'assets/arte/navi_${widget.humor.name}.svg',
      width: widget.largura,
      height: widget.altura,
      fit: BoxFit.contain,
      colorMapper: _Paleta(widget.cor),
    );
    final c = _ctrl;
    if (c == null) return arte;
    return AnimatedBuilder(
      animation: c,
      child: arte,
      builder: (context, filho) {
        final t = Curves.easeInOut.transform(c.value);
        return Transform.translate(
          offset: Offset(0, -5 * t),
          child: Transform.scale(scale: 1 + 0.012 * t, alignment: Alignment.bottomCenter, child: filho),
        );
      },
    );
  }
}

/// Troca as cores-coringa do SVG (#FF0001 a #FF0006) pelas do elemento.
class _Paleta extends ColorMapper {
  const _Paleta(this.base);
  final Color base;

  static const _c1 = Color(0xFFFF0001);
  static const _c2 = Color(0xFFFF0002);
  static const _c3 = Color(0xFFFF0003);
  static const _c4 = Color(0xFFFF0004);
  static const _c5 = Color(0xFFFF0005);
  static const _c6 = Color(0xFFFF0006);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    final placa = Color.lerp(const Color(0xFF10121C), base, 0.07)!;
    return switch (color) {
      _c1 => base,
      _c2 => Color.lerp(base, Colors.black, 0.38)!,
      _c3 => Color.lerp(base, Colors.white, 0.5)!,
      _c4 => placa,
      _c5 => Color.lerp(base, Colors.white, 0.42)!,
      _c6 => Color.lerp(placa, base, 0.16)!,
      _ => color,
    };
  }

  @override
  bool operator ==(Object other) => other is _Paleta && other.base == base;

  @override
  int get hashCode => base.hashCode;
}

/// Só o rosto da NAVI, recortado em quadrado: para retratos pequenos
/// (cabeçalho, menu, balão de conversa).
class RostoVetor extends StatelessWidget {
  final Color cor;
  final Humor humor;
  final double tamanho;

  const RostoVetor({super.key, required this.cor, this.humor = Humor.esperando, required this.tamanho});

  @override
  Widget build(BuildContext context) {
    // A cabeça ocupa ~150 de largura no desenho de 200x240: ela é ampliada
    // até caber no quadrado, centrada no rosto (100, 82).
    final escala = tamanho / 150;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [cor.withValues(alpha: 0.32), cor.withValues(alpha: 0.08)],
        ),
        boxShadow: Efeitos.brilho(cor, forca: 0.12, desfoque: 10),
      ),
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: 200 * escala,
            maxHeight: 240 * escala,
            child: Transform.translate(
              offset: Offset(tamanho / 2 - 100 * escala, tamanho / 2 - 82 * escala),
              child: NaviVetor(
                cor: cor,
                humor: humor,
                largura: 200 * escala,
                altura: 240 * escala,
                respirar: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
