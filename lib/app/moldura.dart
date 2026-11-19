import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// No celular não faz nada. Em tela larga (PC/projetor) desenha um
/// "celular" no meio, para apresentar o app como ele fica no aparelho, e
/// a identificação do projeto ao lado quando houver espaço.
class Moldura extends StatelessWidget {
  final Widget child;

  const Moldura({super.key, required this.child});

  static const _tela = Size(360, 780);
  static const _borda = 10.0;

  @override
  Widget build(BuildContext context) {
    final midia = MediaQuery.of(context);
    if (midia.size.width < 600) return child;
    final comLegenda = midia.size.width >= 1000;

    final celular = Container(
      padding: const EdgeInsets.all(_borda),
      decoration: BoxDecoration(
        color: const Color(0xFF07060B),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF2E2A3B)),
        boxShadow: [
          BoxShadow(
            color: Cores.roxo.withValues(alpha: 0.18),
            blurRadius: 60,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: SizedBox.fromSize(
        size: _tela,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: MediaQuery(
            data: midia.copyWith(
              size: _tela,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [Color(0xFF221B3D), Color(0xFF0B0A12)],
        ),
      ),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (comLegenda) ...[
                  const _Legenda(),
                  const SizedBox(width: 72),
                ],
                celular,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Identificação do projeto ao lado do celular, para a apresentação.
class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    // Fora do Navigator/Scaffold: o texto precisa do próprio estilo base.
    return DefaultTextStyle(
      style: const TextStyle(color: Cores.textoSuave, fontSize: 14, height: 1.5),
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Cores.roxoClaro, Color(0xFF7A5CF0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_stories, color: Color(0xFF1B1725), size: 28),
            ),
            const SizedBox(height: 22),
            const Text(
              'Códice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Um diário pessoal onde uma criatura digital, o NAVI, '
              'aprende com a convivência.',
            ),
            const SizedBox(height: 26),
            for (final (icone, texto) in const [
              (Icons.view_in_ar_outlined, 'NAVI em 3D com animações do Mixamo'),
              (Icons.psychology_outlined, 'personalidade interpretada pelo Gemma'),
              (Icons.lock_outline, 'login JWT com armazenamento seguro'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(icone, size: 18, color: Cores.roxoClaro),
                    const SizedBox(width: 10),
                    Expanded(child: Text(texto)),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            const Text(
              'Desenvolvimento para Dispositivos Móveis\n'
              'Ramon Couto Santo e Aaron Guerra Goldberg',
              style: TextStyle(color: Cores.textoFraco, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
