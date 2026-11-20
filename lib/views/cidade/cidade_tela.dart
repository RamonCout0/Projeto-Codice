import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';
import 'package:codice_app/widgets/estado_cidade.dart';
import 'package:codice_app/widgets/icones.dart';

class CidadeTela extends StatelessWidget {
  const CidadeTela({super.key});

  @override
  Widget build(BuildContext context) {
    final cidade = context.watch<CidadeNavi>();
    final nome = context.watch<Sessao>().perfil.nome;
    final lugares = cidade.lugares;
    final onde = cidade.situacao;
    final total = lugares.fold<int>(0, (soma, l) => soma + l.presentes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Cidade'),
        TituloGrande(
          'Cidade',
          subtitulo: onde == null
              ? 'a cidade onde $nome vive'
              : '$nome está em ${onde.area} · ${onde.estado}',
        ),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            onRefresh: cidade.atualizar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (lugares.isEmpty)
                  AvisoCidade(cidade)
                else ...[
                  CartaoDestaque(
                    icone: Ic.cidade,
                    cor: Cores.ciano,
                    titulo: 'NAVICity',
                    texto:
                        '${lugares.length} lugares · $total '
                        '${total == 1 ? 'NAVI' : 'NAVIs'} na cidade agora.',
                  ),
                  const SizedBox(height: 16),
                  for (final lugar in lugares) ...[
                    CartaoLista(
                      icone: lugar.icone,
                      corIcone: lugar.voce ? Cores.verde : Cores.roxo,
                      titulo: lugar.nome,
                      subtitulo: lugar.voce
                          ? 'você está aqui · ${lugar.descricao}'
                          : lugar.descricao,
                      onTap: () => Navigator.pushNamed(
                        context,
                        Rotas.lugar,
                        arguments: lugar,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
