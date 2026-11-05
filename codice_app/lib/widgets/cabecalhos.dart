import 'package:flutter/material.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/status_bar.dart';

class CabecalhoAba extends StatelessWidget {
  final String titulo;

  const CabecalhoAba(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 0),
      child: Row(
        children: [
          const BotaoMenu(),
          Text(
            titulo,
            style: const TextStyle(color: Color(0xFF8D8996), fontSize: 14),
          ),
          const Spacer(),
          const StatusBar(),
        ],
      ),
    );
  }
}

/// Cabeçalho das telas empilhadas: a seta faz pop no Navigator mais
/// próximo (o da aba, ou o raiz no caso das Configurações).
class CabecalhoDetalhe extends StatelessWidget {
  final String titulo;

  const CabecalhoDetalhe(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'voltar',
            child: InkResponse(
              radius: 18,
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, size: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8D8996), fontSize: 14),
            ),
          ),
          const StatusBar(),
        ],
      ),
    );
  }
}

/// Título grande logo abaixo do cabeçalho.
class TituloGrande extends StatelessWidget {
  final String texto;
  final String? subtitulo;

  const TituloGrande(this.texto, {super.key, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitulo!,
              style: const TextStyle(color: Color(0xFF8B8595), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
