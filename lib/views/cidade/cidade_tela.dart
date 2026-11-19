import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/data/lugares_demo.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';

class CidadeTela extends StatelessWidget {
  const CidadeTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Cidade'),
        TituloGrande(
          'Cidade',
          subtitulo: 'lugares que ${context.watch<Sessao>().perfil.nome} conhece',
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: lugares.length + 1,
            separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return CartaoDestaque(
                  icone: Icons.location_city,
                  cor: Cores.ciano,
                  titulo: 'NAVICity',
                  texto:
                      '${lugares.length} lugares revelados. Outros aparecem '
                      'quando você passa por lugares de verdade.',
                );
              }
              final lugar = lugares[i - 1];
              return CartaoLista(
                icone: lugar.icone,
                titulo: lugar.nome,
                subtitulo: lugar.comoRevelou,
                onTap: () =>
                    Navigator.pushNamed(context, Rotas.lugar, arguments: lugar),
              );
            },
          ),
        ),
      ],
    );
  }
}
