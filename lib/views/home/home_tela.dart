import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/views/home/palco_navi.dart';
import 'package:codice_app/views/home/partes_home.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

class HomeTela extends StatelessWidget {
  const HomeTela({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Estilos.margem,
        0,
        Estilos.margem,
        Estilos.margem,
      ),
      children: const [
        CabecalhoAba('Home'),
        SizedBox(height: 12),
        Row(
          children: [
            Text('Frost', style: Estilos.titulo),
            SizedBox(width: 10),
            Flexible(
              child: Pilula(
                '8 anos • criança',
                cor: Cores.textoSecundario,
                fundo: Cores.painel,
                borda: Color(0xFF383345),
              ),
            ),
            SizedBox(width: 10),
            Spacer(),
            _BotaoImportar(),
          ],
        ),
        SizedBox(height: 14),
        PalcoNavi(),
        SizedBox(height: 14),
        CartaoPergunta(),
        SizedBox(height: 12),
        Row(
          children: [
            AcaoRapida(Icons.article_outlined, 'escrever'),
            SizedBox(width: 8),
            AcaoRapida(Icons.search, 'lembrar'),
            SizedBox(width: 8),
            AcaoRapida(Icons.alarm, 'alarme'),
            SizedBox(width: 8),
            AcaoRapida(Icons.mic_none, 'falar'),
          ],
        ),
        SizedBox(height: 16),
        BarraVigor(78),
      ],
    );
  }
}

/// Atalho para a tela de importar o modelo 3D.
class _BotaoImportar extends StatelessWidget {
  const _BotaoImportar();

  @override
  Widget build(BuildContext context) {
    return Pilula(
      'trocar NAVI',
      icone: Icons.view_in_ar_outlined,
      onTap: () =>
          Navigator.of(context, rootNavigator: true).pushNamed(Rotas.importar),
    );
  }
}
