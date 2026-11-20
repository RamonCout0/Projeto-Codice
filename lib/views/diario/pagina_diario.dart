import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/icones.dart';

String plural(int n, String palavra) =>
    '$n ${n == 1 ? palavra : '${palavra}s'}';

/// A folha do diário: campo de texto e contador de palavras ao vivo.
class PaginaDiario extends StatelessWidget {
  final TextEditingController texto;
  final FocusNode foco;
  final bool habilitada;
  final ValueChanged<String> aoDigitar;
  final int palavras;
  final int minimo;

  const PaginaDiario({
    super.key,
    required this.texto,
    required this.foco,
    required this.habilitada,
    required this.aoDigitar,
    required this.palavras,
    required this.minimo,
  });

  @override
  Widget build(BuildContext context) {
    final falta = minimo - palavras;
    final pronto = falta <= 0;
    final corStatus = pronto ? Cores.verde : Cores.ambar;
    final estiloTexto = TextStyle(
      color: Cores.texto,
      fontSize: 15,
      height: 1.55,
    );

    return Painel(
      altura: 220,
      borda: foco.hasFocus ? Cores.roxoBorda : Cores.borda,
      raio: BorderRadius.circular(17),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 11),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: texto,
              focusNode: foco,
              enabled: habilitada,
              onChanged: aoDigitar,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: estiloTexto,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.only(top: 6),
                hintText:
                    'Acordei mal de novo, não preguei o olho. '
                    'A prova de física ficou pra quinta...',
                hintStyle: estiloTexto.copyWith(color: Cores.textoFraco),
              ),
            ),
          ),
          Divider(height: 18, color: Cores.linha),
          Row(
            children: [
              Text(plural(palavras, 'palavra'), style: Estilos.rotulo),
              const Spacer(),
              IconeCodice(
                pronto ? Ic.checkCirculo : Ic.ampulheta,
                color: corStatus,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  pronto
                      ? 'ela já consegue guardar'
                      : 'faltam $falta para ela entender',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Estilos.rotulo.copyWith(color: corStatus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dica no fim da página.
class DicaDiario extends StatelessWidget {
  const DicaDiario({super.key});

  @override
  Widget build(BuildContext context) {
    return Painel(
      cor: Cores.cartaoClaro,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeCodice(Ic.lampada, color: Cores.ambar, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'escreva solto, do tamanho que der\n',
                    style: TextStyle(
                      color: Cores.texto,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        'nada vira memória sem você confirmar. quanto mais '
                        'você ensina, mais ela cresce.',
                    style: TextStyle(
                      color: Cores.textoApagado,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
