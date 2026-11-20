import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/cartao_lista.dart';
import 'package:codice_app/widgets/estado_cidade.dart';
import 'package:codice_app/widgets/foto_navi.dart';
import 'package:codice_app/widgets/icones.dart';

class EncontrosTela extends StatelessWidget {
  const EncontrosTela({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: a lista se redesenha sozinha quando chegam fatos novos.
    final cidade = context.watch<CidadeNavi>();
    final nome = context.watch<Sessao>().perfil.nome;
    final navis = cidade.encontros;
    final media = navis.isEmpty
        ? 0
        : navis.map((n) => n.afinidade).reduce((a, b) => a + b) ~/ navis.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Encontros'),
        TituloGrande('Encontros', subtitulo: 'NAVIs que $nome conheceu na cidade'),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            onRefresh: cidade.atualizar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (cidade.situacao == null)
                  AvisoCidade(cidade)
                else if (navis.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
                    child: Column(
                      children: [
                        IconeCodice(
                          Ic.pessoas,
                          size: 44,
                          color: Cores.textoFraco,
                        ),
                        const SizedBox(height: 14),
                        Text('Ninguém por enquanto', style: Estilos.tituloDialogo),
                        const SizedBox(height: 6),
                        Text(
                          '$nome ainda não conheceu ninguém. Quando ela '
                          'cruzar com outro NAVI na cidade, ele aparece aqui.',
                          textAlign: TextAlign.center,
                          style: Estilos.legenda,
                        ),
                      ],
                    ),
                  )
                else ...[
                  CartaoDestaque(
                    icone: Ic.pessoas,
                    cor: Cores.rosa,
                    titulo:
                        '${navis.length} ${navis.length == 1 ? 'NAVI conhecido' : 'NAVIs conhecidos'}',
                    texto: 'afinidade média de $media%. Toque em um para dar um apelido.',
                    progresso: media / 100,
                  ),
                  const SizedBox(height: 16),
                  for (final navi in navis) ...[
                    CartaoLista(
                      icone: Ic.navi,
                      lider: FotoNavi(cor: navi.cor, gm: navi.gm, tamanho: 52),
                      titulo: navi.apelido == null ? navi.nome : '${navi.apelido}  (${navi.nome})',
                      subtitulo: '${navi.quando} · ${navi.ultimaArea} · afinidade ${navi.afinidade}%',
                      onTap: () => Navigator.pushNamed(
                        context,
                        Rotas.naviEncontrado,
                        arguments: navi,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
