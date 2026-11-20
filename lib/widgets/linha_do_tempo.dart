import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/icones.dart';

class ItemTempo {
  final Ic icone;
  final String texto;
  final String quando;
  final Color? cor;

  const ItemTempo({required this.icone, required this.texto, required this.quando, this.cor});
}

/// Histórico em linha do tempo: ícone, fio ligando os itens, texto e "há X".
class LinhaDoTempo extends StatelessWidget {
  final List<ItemTempo> itens;

  const LinhaDoTempo(this.itens, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itens.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (itens[i].cor ?? Cores.roxo).withValues(alpha: 0.14),
                          border: Border.all(color: (itens[i].cor ?? Cores.roxo).withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: IconeCodice(itens[i].icone, color: itens[i].cor ?? Cores.roxo, size: 16),
                        ),
                      ),
                      if (i < itens.length - 1)
                        Expanded(child: Container(width: 1.5, color: Cores.linha)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 18, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itens[i].texto, style: Estilos.corpo.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(itens[i].quando, style: Estilos.legenda),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
