import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/avatar_navi.dart';

/// O palco da NAVI: o fundo em degradê com ela de pé, os pés na base, e
/// um brilho no chão na cor do elemento.
class PalcoNavi extends StatelessWidget {
  const PalcoNavi({super.key});

  @override
  Widget build(BuildContext context) {
    final cor = context.watch<Sessao>().perfil.elemento.cor;
    return Container(
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Color.lerp(const Color(0xFF5A4B87), cor, 0.25)!),
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.95,
          colors: [Color.lerp(const Color(0xFF192235), cor, 0.08)!, Cores.palco],
        ),
      ),
      child: Stack(
        children: [
          // Brilho no chão: liga os pés ao palco sem desenhar anéis.
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Container(
                width: 130,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(65, 6)),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            top: 16,
            bottom: 10,
            child: AvatarNavi(
              enquadramento: Enquadramento.corpo,
              alinhamento: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
}
