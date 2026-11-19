import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/models/navi_encontrado.dart';
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
    if (!context.mounted || novo == null || novo.isEmpty) return;
    context.read<EstadoCodice>().alterarApelido(atual.nome, novo);
    final nome = context.read<Sessao>().perfil.nome;
    avisar(context, '$nome agora chama ${atual.nome} de "$novo"');
  }

  @override
  Widget build(BuildContext context) {
    final atual = context.watch<EstadoCodice>().obterNavi(navi.nome) ?? navi;
    return Material(
      color: Cores.fundo,
      child: ListView(
        children: [
          CabecalhoDetalhe('Encontros / ${atual.nome}'),
          const SizedBox(height: 30),
          IconeDestaque(Icons.smart_toy_outlined, cor: atual.cor),
          TituloGrande(
            atual.comoChamar,
            subtitulo: atual.apelido == null
                ? atual.quando
                : 'apelido de ${atual.nome} · ${atual.quando}',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'afinidade ${atual.afinidade}%',
                  style: const TextStyle(color: Cores.roxoClaro, fontSize: 11),
                ),
                const SizedBox(height: 6),
                BarraProgresso(
                  atual.afinidade / 100,
                  cor: atual.cor,
                  altura: 6,
                ),
                const SizedBox(height: 16),
                Text(
                  '«${atual.relato.replaceAll('Frost', context.watch<Sessao>().perfil.nome)}»',
                  style: Estilos.corpoSuave,
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => _darApelido(context, atual),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    atual.apelido == null ? 'dar um apelido' : 'mudar apelido',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
