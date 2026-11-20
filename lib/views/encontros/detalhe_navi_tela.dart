import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/services/narracao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/widgets/foto_navi.dart';
import 'package:codice_app/widgets/linha_do_tempo.dart';
import 'package:codice_app/views/cidade/lugar_tela.dart' show iconeDoFato;
import 'package:codice_app/widgets/icones.dart';

class DetalheNaviTela extends StatelessWidget {
  final NaviEncontrado navi;

  const DetalheNaviTela({super.key, required this.navi});

  /// Empilha a tela de apelido na mesma aba e espera o valor do pop.
  Future<void> _darApelido(BuildContext context, NaviEncontrado atual) async {
    final novo = await Navigator.pushNamed<String>(
      context,
      Rotas.apelido,
      arguments: atual.comoChamar,
    );
    if (!context.mounted || novo == null || novo.trim().isEmpty) return;
    await context.read<CidadeNavi>().alterarApelido(atual.nome, novo);
    if (!context.mounted) return;
    final nome = context.read<Sessao>().perfil.nome;
    avisar(context, '$nome agora chama ${atual.nome} de "${novo.trim()}"');
  }

  @override
  Widget build(BuildContext context) {
    final cidade = context.watch<CidadeNavi>();
    final nome = context.watch<Sessao>().perfil.nome;
    final atual = cidade.encontro(navi.nome) ?? navi;
    final historico = cidade.fatosCom(atual.nome);

    return Material(
      color: Cores.fundo,
      child: ListView(
        children: [
          CabecalhoDetalhe('Encontros / ${atual.nome}'),
          const SizedBox(height: 30),
          Center(child: FotoNavi(cor: atual.cor, gm: atual.gm, tamanho: 120, redonda: true, humor: Humor.esperando)),
          TituloGrande(
            atual.comoChamar,
            subtitulo: atual.apelido == null
                ? '${atual.quando} · ${atual.ultimaArea}'
                : 'apelido de ${atual.nome} · ${atual.quando}',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (atual.gm)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pilula(
                      'GM da cidade',
                      icone: Ic.chip,
                      cor: Cores.ciano,
                      fundo: Cores.ciano.withValues(alpha: 0.12),
                      borda: Cores.ciano,
                    ),
                  ),
                if (atual.gm) const SizedBox(height: 12),
                Text(
                  'afinidade ${atual.afinidade}% · ${tomEmTexto(atual.tom)} · '
                  '${atual.encontros} ${atual.encontros == 1 ? 'encontro' : 'encontros'}',
                  style: TextStyle(color: Cores.roxoClaro, fontSize: 13),
                ),
                const SizedBox(height: 8),
                BarraProgresso(atual.afinidade / 100, cor: atual.cor, altura: 8),
                const SizedBox(height: 16),
                Text('«${atual.relato}»', style: Estilos.corpoSuave),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => _darApelido(context, atual),
                  icon: const IconeCodice(Ic.editar, size: 16),
                  label: Text(atual.apelido == null ? 'dar um apelido' : 'mudar apelido'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('HISTÓRICO', style: Estilos.secao),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: LinhaDoTempo([
              for (final f in historico.take(20))
                ItemTempo(
                  icone: iconeDoFato(f.tipo),
                  texto: narrar(f, nome),
                  quando: cidade.quando(f.quandoSegundos),
                  cor: atual.cor,
                ),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
