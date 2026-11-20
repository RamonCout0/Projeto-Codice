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
import 'package:codice_app/widgets/cartao_lista.dart';

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
          IconeDestaque(atual.gm ? Icons.memory : Icons.smart_toy_outlined, cor: atual.cor),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Pilula(
                      'GM da cidade',
                      icone: Icons.memory,
                      cor: Cores.ciano,
                      fundo: Color(0x1F65D6D6),
                      borda: Cores.ciano,
                    ),
                  ),
                if (atual.gm) const SizedBox(height: 12),
                Text(
                  'afinidade ${atual.afinidade}% · ${tomEmTexto(atual.tom)} · '
                  '${atual.encontros} ${atual.encontros == 1 ? 'encontro' : 'encontros'}',
                  style: const TextStyle(color: Cores.roxoClaro, fontSize: 13),
                ),
                const SizedBox(height: 8),
                BarraProgresso(atual.afinidade / 100, cor: atual.cor, altura: 8),
                const SizedBox(height: 16),
                Text('«${atual.relato}»', style: Estilos.corpoSuave),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => _darApelido(context, atual),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(atual.apelido == null ? 'dar um apelido' : 'mudar apelido'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('HISTÓRICO', style: Estilos.secao),
          ),
          for (final f in historico.take(20))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CartaoLista(
                icone: Icons.history_rounded,
                titulo: narrar(f, nome),
                subtitulo: cidade.quando(f.quandoSegundos),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
