import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/controllers/sessao.dart';
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
        _Identidade(),
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

/// Nome e elemento do NAVI; tocar abre a personalidade.
class _Identidade extends StatelessWidget {
  const _Identidade();

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<Sessao>().perfil;
    final elemento = perfil.elemento;
    return Row(
      children: [
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(Rotas.perfil),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      perfil.nome,
                      style: Estilos.titulo,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 14, color: Cores.textoFraco),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Pilula(
          '${elemento.titulo} · 8 anos',
          icone: elemento.icone,
          cor: elemento.cor,
          fundo: elemento.cor.withValues(alpha: 0.1),
          borda: elemento.cor.withValues(alpha: 0.35),
        ),
        const Spacer(),
        const _BotaoImportar(),
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
      '3D',
      icone: Icons.view_in_ar_outlined,
      onTap: () =>
          Navigator.of(context, rootNavigator: true).pushNamed(Rotas.importar),
    );
  }
}
