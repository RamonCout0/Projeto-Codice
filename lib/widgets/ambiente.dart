import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Fundo das telas principais: a cor de fundo do tema com dois clarões
/// suaves (roxo no canto de cima, azul-esverdeado embaixo), para o app não
/// ficar "chapado".
class FundoAmbiente extends StatelessWidget {
  const FundoAmbiente({super.key});

  @override
  Widget build(BuildContext context) {
    final forca = Cores.claro ? 0.55 : 1.0;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Cores.fundo),
        child: LayoutBuilder(
          builder: (context, lim) => Stack(
            children: [
              Positioned(
                left: -lim.maxWidth * 0.4,
                top: -lim.maxWidth * 0.5,
                child: _Clarao(cor: Cores.roxo.withValues(alpha: 0.20 * forca), diametro: lim.maxWidth * 1.5),
              ),
              Positioned(
                right: -lim.maxWidth * 0.5,
                bottom: -lim.maxWidth * 0.2,
                child: _Clarao(cor: Cores.ciano.withValues(alpha: 0.10 * forca), diametro: lim.maxWidth * 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clarao extends StatelessWidget {
  final Color cor;
  final double diametro;

  const _Clarao({required this.cor, required this.diametro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [cor, cor.withValues(alpha: 0)]),
      ),
    );
  }
}
