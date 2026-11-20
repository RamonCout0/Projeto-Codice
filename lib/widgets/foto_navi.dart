import 'package:flutter/material.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/widgets/icones.dart';
import 'package:codice_app/widgets/navi_vetor.dart';

/// Retrato vetorial de um NAVI da cidade (ou da Iris), na cor dele, com o
/// selo de GM quando for o caso.
class FotoNavi extends StatelessWidget {
  final Color cor;
  final bool gm;
  final double tamanho;
  final bool redonda;
  final Humor humor;

  const FotoNavi({
    super.key,
    required this.cor,
    this.gm = false,
    this.tamanho = 48,
    this.redonda = false,
    this.humor = Humor.esperando,
  });

  @override
  Widget build(BuildContext context) {
    final forma = redonda ? BorderRadius.circular(tamanho) : BorderRadius.circular(tamanho * 0.3);
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: forma,
              border: Border.all(color: cor.withValues(alpha: 0.5), width: tamanho > 80 ? 2 : 1.2),
              boxShadow: tamanho > 80 ? Efeitos.brilho(cor, forca: 0.3, desfoque: 30) : null,
            ),
            child: ClipRRect(
              borderRadius: forma,
              child: RostoVetor(cor: cor, humor: humor, tamanho: tamanho),
            ),
          ),
          if (gm)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: tamanho * 0.36,
                height: tamanho * 0.36,
                decoration: BoxDecoration(
                  color: Cores.cartao,
                  shape: BoxShape.circle,
                  border: Border.all(color: cor, width: 1.4),
                ),
                child: Center(child: IconeCodice(Ic.gm, color: cor, size: tamanho * 0.22)),
              ),
            ),
        ],
      ),
    );
  }
}
