import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/status_bar.dart';
import 'package:codice_app/widgets/chao.dart';
import 'package:codice_app/ui/imagens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Uma margem só para a tela inteira: é o que faz as bordas do palco,
  /// do cartão e dos botões caírem na mesma linha.
  static const double margem = 16;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(margem, 5, margem, margem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              BotaoMenu(),
              Text(
                'Home',
                style: TextStyle(color: Color(0xFF8D8996), fontSize: 14),
              ),
              Spacer(),
              StatusBar(),
            ],
          ),
          const SizedBox(height: 20),
          _cabecalho(),
          const SizedBox(height: 14),
          _palco(),
          const SizedBox(height: 14),
          _pergunta(),
          const SizedBox(height: 12),
          Row(
            children: [
              _acao(Icons.article_outlined, 'escrever'),
              const SizedBox(width: 8),
              _acao(Icons.search, 'lembrar'),
              const SizedBox(width: 8),
              _acao(Icons.alarm, 'alarme'),
              const SizedBox(width: 8),
              _acao(Icons.mic_none, 'falar'),
            ],
          ),
          const SizedBox(height: 16),
          _vigor(78),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        const Text(
          'Frost',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF171522),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF383345)),
          ),
          child: const Text(
            '8 anos • criança',
            style: TextStyle(
              color: Color(0xFFB8B2C5),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF211A3B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF45356F)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_natural, color: kPurple, size: 13),
              SizedBox(width: 5),
              Text(
                'ficha',
                style: TextStyle(
                  color: kPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// O palco da Frost. A ordem do Stack é a profundidade: metade de trás
  /// dos anéis → Frost → metade da frente. Assim ela fica DENTRO dos
  /// anéis, com os pés no centro, em vez de ter linhas riscando as botas.
  Widget _palco() {
    const alturaChao = 44.0;
    const baseDoChao = 12.0;
    // Os pés ficam exatamente no centro das elipses.
    const pes = baseDoChao + alturaChao / 2;

    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF5A4B87)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [
                      const Color(0xFF192235).withValues(alpha: 0.8),
                      const Color(0xFF111624).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: baseDoChao,
              height: alturaChao,
              child: CustomPaint(
                painter: GroundCirclesPainter(metade: MetadeDoChao.tras),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 16,
              bottom: pes,
              child: Image(
                image: frostImage,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: baseDoChao,
              height: alturaChao,
              child: CustomPaint(
                painter: GroundCirclesPainter(metade: MetadeDoChao.frente),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pergunta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF36250D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5B411B)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: Color(0xFFF0B74B),
                      size: 15,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'ela quer entender uma coisa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFF0B74B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7),
                Text(
                  '«Você mudou de emprego?»',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'dois fatos que ela guarda se contradizem.',
                  style: TextStyle(color: Color(0xFF918676), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0B74B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'resolver',
              style: TextStyle(
                color: Color(0xFF251A09),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acao(IconData icone, String rotulo) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: kPurple, size: 18),
            const SizedBox(height: 7),
            Text(
              rotulo,
              style: const TextStyle(
                color: Color(0xFFB2ADBE),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de vigor com o valor de verdade: antes ela ficava sempre
  /// cheia, mesmo mostrando 78.
  Widget _vigor(int valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'VIGOR',
              style: TextStyle(
                color: Color(0xFF8D879B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '$valor',
              style: const TextStyle(
                color: Color(0xFFB9B3C3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: valor / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFF232030),
            color: const Color(0xFF65D6D6),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'descansou bem, sem desgaste acumulado.',
          style: TextStyle(color: Color(0xFF777181), fontSize: 9),
        ),
      ],
    );
  }
}
