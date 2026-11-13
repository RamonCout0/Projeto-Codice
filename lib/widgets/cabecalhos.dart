import 'package:flutter/material.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/menu.dart';

/// Linha do topo das abas: botão do menu + nome da aba.
class CabecalhoAba extends StatelessWidget {
  final String titulo;

  const CabecalhoAba(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const BotaoMenu(),
          Text(titulo, style: Estilos.cabecalho),
        ],
      ),
    );
  }
}

/// Topo das telas empilhadas: a seta faz pop no Navigator mais próximo.
class CabecalhoDetalhe extends StatelessWidget {
  final String titulo;

  const CabecalhoDetalhe(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            tooltip: 'voltar',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: Estilos.cabecalho,
            ),
          ),
        ],
      ),
    );
  }
}

class TituloGrande extends StatelessWidget {
  final String texto;
  final String? subtitulo;

  const TituloGrande(this.texto, {super.key, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto, style: Estilos.titulo),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(subtitulo!, style: Estilos.legenda),
          ],
        ],
      ),
    );
  }
}
