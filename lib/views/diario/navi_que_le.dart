import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/views/diario/humor_visual.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/basicos.dart';

/// A NAVI no topo do Diário: rosto tocável, balão de fala e a barra
/// de conhecimento "rumo aos 14".
class NaviQueLe extends StatelessWidget {
  final Humor humor;
  final String fala;
  final bool pulando;
  final int carinhos;
  final double conhecimento;
  final VoidCallback aoTocar;
  final VoidCallback aoTocarDuasVezes;
  final VoidCallback aoSegurar;

  const NaviQueLe({
    super.key,
    required this.humor,
    required this.fala,
    required this.pulando,
    required this.carinhos,
    required this.conhecimento,
    required this.aoTocar,
    required this.aoTocarDuasVezes,
    required this.aoSegurar,
  });

  @override
  Widget build(BuildContext context) {
    const legenda = TextStyle(color: Color(0xFF8D879B), fontSize: 11);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: aoTocar,
              onDoubleTap: aoTocarDuasVezes,
              onLongPress: aoSegurar,
              child: AnimatedScale(
                scale: pulando ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Painel(
                  cor: Cores.palco,
                  borda: humor.cor,
                  padding: const EdgeInsets.all(1.5),
                  raio: BorderRadius.circular(17),
                  child: AvatarNavi(
                    largura: 58,
                    altura: 58,
                    raio: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _balao(context)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Flexible(
              child: Text(
                'toque · dois toques · segure',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Cores.textoFraco, fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: BarraProgresso(conhecimento, altura: 4)),
            const SizedBox(width: 6),
            const Text('rumo aos 14', style: legenda),
          ],
        ),
      ],
    );
  }

  Widget _balao(BuildContext context) {
    const raio = Radius.circular(15);
    return Painel(
      borda: humor.cor,
      raio: const BorderRadius.only(
        topRight: raio,
        bottomLeft: raio,
        bottomRight: raio,
      ),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(humor.icone, color: humor.cor, size: 12),
              const SizedBox(width: 5),
              Text(
                '${context.watch<Sessao>().perfil.nome} · 8 anos',
                style: TextStyle(
                  color: Cores.textoSecundario,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (carinhos > 0)
                Text(
                  '♥ $carinhos',
                  style: const TextStyle(color: Cores.rosa, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            fala,
            style: const TextStyle(
              color: Cores.texto,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
