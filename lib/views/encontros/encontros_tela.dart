import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/estado_codice.dart';
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
        const TituloGrande(
          'Encontros',
          subtitulo: 'NAVIs que a Frost conheceu por perto',
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: navis.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final navi = navis[i];
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
