import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/services/narracao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';
import 'package:codice_app/widgets/icones.dart';
import 'package:codice_app/widgets/linha_do_tempo.dart';

class LugarTela extends StatelessWidget {
  final Lugar lugar;

  const LugarTela({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    final cidade = context.watch<CidadeNavi>();
    final nome = context.watch<Sessao>().perfil.nome;
    // O lugar muda enquanto a tela está aberta (quem chega, quem sai).
    final atual = cidade.lugares.where((l) => l.id == lugar.id).firstOrNull ?? lugar;
    final fatos = cidade.fatosDoLugar(atual.nome);

    return Material(
      color: Cores.fundo,
      child: ListView(
        children: [
          CabecalhoDetalhe('Cidade / ${atual.nome}'),
          const SizedBox(height: 30),
          IconeDestaque(atual.icone, cor: atual.voce ? Cores.verde : Cores.roxo),
          TituloGrande(
            atual.nome,
            subtitulo: atual.voce ? '$nome está aqui agora' : atual.descricao,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(atual.descricao, style: Estilos.corpoSuave),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('O QUE ACONTECEU AQUI', style: Estilos.secao),
          ),
          if (fatos.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text(
                '$nome ainda não viveu nada neste lugar.',
                style: Estilos.legenda,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: LinhaDoTempo([
                for (final f in fatos.take(20))
                  ItemTempo(
                    icone: iconeDoFato(f.tipo),
                    texto: narrar(f, nome),
                    quando: cidade.quando(f.quandoSegundos),
                    cor: Cores.roxo,
                  ),
              ]),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Ic iconeDoFato(String tipo) => switch (tipo) {
  'conheceu' => Ic.acenar,
  'conversou' => Ic.conversa,
  'recusou' => Ic.bloquear,
  'mudou_tom' => Ic.coracao,
  'partiu' => Ic.caminhar,
  'chegou' || 'entrou' => Ic.lugar,
  _ => Ic.circulo,
};
