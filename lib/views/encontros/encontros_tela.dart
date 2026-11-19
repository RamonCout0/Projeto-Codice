import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';

class EncontrosTela extends StatelessWidget {
  const EncontrosTela({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: a lista se redesenha sozinha quando um apelido muda.
    final navis = context.watch<EstadoCodice>().navis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Encontros'),
        TituloGrande(
          'Encontros',
          subtitulo:
              'NAVIs que ${context.watch<Sessao>().perfil.nome} conheceu por perto',
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: navis.length + 1,
            separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                final media = navis.isEmpty
                    ? 0
                    : navis.map((n) => n.afinidade).reduce((a, b) => a + b) ~/
                          navis.length;
                return CartaoDestaque(
                  icone: Icons.bluetooth_searching,
                  cor: Cores.rosa,
                  titulo: '${navis.length} NAVIs encontrados',
                  texto: 'afinidade média de $media%. Toque em um para dar '
                      'um apelido.',
                  progresso: media / 100,
                );
              }
              final navi = navis[i - 1];
              return CartaoLista(
                icone: Icons.smart_toy_outlined,
                corIcone: navi.cor,
                titulo: navi.apelido == null
                    ? navi.nome
                    : '${navi.apelido}  (${navi.nome})',
                subtitulo: '${navi.quando} · afinidade ${navi.afinidade}%',
                onTap: () => Navigator.pushNamed(
                  context,
                  Rotas.naviEncontrado,
                  arguments: navi,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
