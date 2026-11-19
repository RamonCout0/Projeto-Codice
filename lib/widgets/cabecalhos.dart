import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/menu.dart';

/// Linha do topo das abas: menu, nome da aba e o retrato do NAVI (que abre
/// a personalidade).
class CabecalhoAba extends StatelessWidget {
  final String titulo;

  const CabecalhoAba(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    final cor = context.watch<Sessao>().perfil.elemento.cor;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const BotaoMenu(),
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: Estilos.cabecalho,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: 'personalidade do NAVI',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(Rotas.perfil),
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cor.withValues(alpha: 0.8)),
                  ),
                  child: const AvatarNavi(largura: 28, altura: 28, redondo: true),
                ),
              ),
            ),
          ),
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
      height: 48,
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto, style: Estilos.titulo),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: Estilos.legenda.copyWith(fontSize: 11, color: Cores.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}
