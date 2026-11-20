import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/widgets/avatar_navi.dart';

/// O palco da NAVI: fundo escuro com uma aura na cor do elemento atrás dela,
/// ela de pé, e um brilho no chão que liga os pés ao palco.
class PalcoNavi extends StatelessWidget {
  const PalcoNavi({super.key});

  @override
  Widget build(BuildContext context) {
    final cor = context.watch<Sessao>().perfil.elemento.cor;
    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Color.lerp(Cores.bordaRoxa, cor, 0.35)!),
        boxShadow: Efeitos.brilho(cor, forca: 0.14, desfoque: 40),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(Cores.palco, cor, 0.1)!, Cores.palco],
        ),
      ),
      child: Stack(
        children: [
          // Aura: um círculo suave de luz do elemento atrás do corpo.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.15),
                  radius: 0.75,
                  colors: [cor.withValues(alpha: 0.24), cor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          // Brilho no chão.
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Container(
                width: 160,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.elliptical(80, 7)),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.55),
                      blurRadius: 26,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            top: 20,
            bottom: 14,
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
