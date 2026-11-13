import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/views/home/aneis_do_chao.dart';
import 'package:codice_app/widgets/avatar_navi.dart';

/// O palco da NAVI. A ordem do Stack é a profundidade: metade de trás
/// dos anéis → NAVI → metade da frente, para ela ficar DENTRO dos anéis.
class PalcoNavi extends StatelessWidget {
  const PalcoNavi({super.key});

  static const _alturaChao = 44.0;
  static const _baseChao = 12.0;

  @override
  Widget build(BuildContext context) {
    Widget chao(MetadeDoChao metade) => Positioned(
      left: 0,
      right: 0,
      bottom: _baseChao,
      height: _alturaChao,
      child: CustomPaint(painter: AneisDoChao(metade)),
    );

    return Container(
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF5A4B87)),
        gradient: const RadialGradient(
          center: Alignment(0, -0.15),
          radius: 0.95,
          colors: [Color(0xFF192235), Cores.palco],
        ),
      ),
      child: Stack(
        children: [
          chao(MetadeDoChao.tras),
          const Positioned(
            left: 0,
            right: 0,
            top: 16,
            // Os pés ficam no centro das elipses.
            bottom: _baseChao + _alturaChao / 2,
            child: AvatarNavi(
              enquadramento: Enquadramento.corpo,
              alinhamento: Alignment.bottomCenter,
            ),
          ),
          chao(MetadeDoChao.frente),
        ],
      ),
    );
  }
}
