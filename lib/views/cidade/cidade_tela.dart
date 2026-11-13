import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/data/lugares_demo.dart';
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
        const TituloGrande('Cidade', subtitulo: 'lugares que a Frost conhece'),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: lugares.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final lugar = lugares[i];
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
