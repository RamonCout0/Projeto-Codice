import 'package:flutter/material.dart';

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  static const Size tamanho = Size(338, 777);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Celular de verdade (tela estreita): a moldura não faz sentido,
        // o app ocupa a tela inteira.
        if (constraints.maxWidth < 500) return child;

        // PC/projetor: desenha o "celular" e encolhe se a janela for
        // baixa, em vez de estourar a altura.
        final midia = MediaQuery.of(context);
        return ColoredBox(
          color: const Color(0xFF292832),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox.fromSize(
                  size: tamanho,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: MediaQuery(
                      data: midia.copyWith(
                        size: tamanho,
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
      },
    );
  }
}
