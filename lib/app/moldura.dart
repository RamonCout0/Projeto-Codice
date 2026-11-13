import 'package:flutter/material.dart';

/// No celular não faz nada. Em tela larga (PC/projetor) desenha um
/// "celular" no meio, para apresentar o app como ele fica no aparelho.
class Moldura extends StatelessWidget {
  final Widget child;

  const Moldura({super.key, required this.child});

  static const _tamanho = Size(360, 780);

  @override
  Widget build(BuildContext context) {
    final midia = MediaQuery.of(context);
    if (midia.size.width < 600) return child;

    return ColoredBox(
      color: const Color(0xFF292832),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox.fromSize(
              size: _tamanho,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: MediaQuery(
                  data: midia.copyWith(
                    size: _tamanho,
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
