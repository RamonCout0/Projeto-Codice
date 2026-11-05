import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/widgets/cartao_lista.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  Future<void> _abrir(NaviEncontrado navi) async {
    debugPrint('[Encontros] pushNamed(${Rotas.naviEncontrado}, '
        'arguments: ${navi.nome})');
    await Navigator.pushNamed(context, Rotas.naviEncontrado, arguments: navi);
    // A lista é atualizada automaticamente pelo EstadoCodice/Provider.
  }

  @override
  Widget build(BuildContext context) {
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
            itemBuilder: (_, i) {
              final navi = navis[i];
              return CartaoLista(
                icone: Icons.smart_toy_outlined,
                corIcone: navi.cor,
                titulo: navi.apelido == null
                    ? navi.nome
                    : '${navi.apelido}  (${navi.nome})',
                subtitulo: '${navi.quando} · afinidade ${navi.afinidade}%',
                onTap: () => _abrir(navi),
              );
            },
          ),
        ),
      ],
    );
  }
}
