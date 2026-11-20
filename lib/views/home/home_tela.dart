import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/estado_codice.dart';
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
      children: [
        const CabecalhoAba('Home'),
        const SizedBox(height: 8),
        const _Identidade(),
        const SizedBox(height: 18),
        const PalcoNavi(),
        const SizedBox(height: 18),
        const CartaoNovidade(),
        const SizedBox(height: 14),
        Row(
          children: [
            AcaoRapida(
              Icons.edit_note_rounded,
              'escrever',
              onTap: () => context.read<NavegacaoAbas>().irPara(2),
            ),
            const SizedBox(width: 10),
            AcaoRapida(
              Icons.chat_bubble_outline_rounded,
              'conversar',
              onTap: () => context.read<NavegacaoAbas>().irPara(1),
            ),
            const SizedBox(width: 10),
            AcaoRapida(
              Icons.location_city,
              'cidade',
              onTap: () => context.read<NavegacaoAbas>().irPara(3),
            ),
            const SizedBox(width: 10),
            AcaoRapida(
              Icons.people_outline_rounded,
              'encontros',
              onTap: () => context.read<NavegacaoAbas>().irPara(4),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const PainelCrescimento(),
      ],
    );
  }
}

/// Saudação, nome e elemento do NAVI; tocar no nome abre a personalidade.
class _Identidade extends StatelessWidget {
  const _Identidade();

  static String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 5) return 'Boa madrugada';
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<Sessao>().perfil;
    final elemento = perfil.elemento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _saudacao(),
          style: Estilos.legenda.copyWith(
            fontSize: 13,
            color: Cores.textoSecundario,
          ),
        ),
        const SizedBox(height: 2),
        InkWell(
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
                    style: Estilos.titulo.copyWith(fontSize: 30),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Cores.textoFraco,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pilula(
              elemento.titulo,
              icone: elemento.icone,
              cor: elemento.cor,
              fundo: elemento.cor.withValues(alpha: 0.12),
              borda: elemento.cor.withValues(alpha: 0.4),
            ),
            Pilula(
              '${context.watch<EstadoCodice>().idade} anos · ${context.watch<EstadoCodice>().fase}',
              icone: Icons.cake_outlined,
              cor: Cores.textoSuave,
              fundo: Cores.cartao,
              borda: Cores.borda,
            ),
            Pilula(
              '3D',
              icone: Icons.view_in_ar_outlined,
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(Rotas.importar),
            ),
          ],
        ),
      ],
    );
  }
}
