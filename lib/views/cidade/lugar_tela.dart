import 'package:flutter/material.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';

class LugarTela extends StatelessWidget {
  final Lugar lugar;

  const LugarTela({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.fundo,
      child: ListView(
        children: [
          CabecalhoDetalhe('Cidade / ${lugar.nome}'),
          const SizedBox(height: 30),
          IconeDestaque(lugar.icone),
          TituloGrande(lugar.nome, subtitulo: lugar.comoRevelou),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Text(lugar.descricao, style: Estilos.corpoSuave),
          ),
        ],
      ),
    );
  }
}
