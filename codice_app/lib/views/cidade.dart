import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/data/lugares_demo.dart';
import 'package:codice_app/widgets/cartao_lista.dart';

class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  void _abrir(BuildContext context, Lugar lugar) {
    debugPrint('[Cidade] pushNamed(${Rotas.lugar}, arguments: ${lugar.nome})');
    Navigator.pushNamed(context, Rotas.lugar, arguments: lugar);
  }

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
                onTap: () => _abrir(context, lugar),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recebe o Lugar pelos arguments da rota nomeada.
class LugarScreen extends StatelessWidget {
  final Lugar lugar;

  const LugarScreen({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoDetalhe('Cidade / ${lugar.nome}'),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFF211B3A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF493A70)),
              ),
              child: Icon(lugar.icone, color: kPurple, size: 42),
            ),
          ),
          TituloGrande(lugar.nome, subtitulo: lugar.comoRevelou),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              lugar.descricao,
              style: const TextStyle(
                color: Color(0xFFC5C1CB),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
