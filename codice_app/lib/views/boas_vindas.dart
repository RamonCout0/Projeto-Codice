import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/status_bar.dart';
import 'package:codice_app/ui/imagens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Login → app. pushReplacement: o login sai da pilha, então o
  /// voltar do Android dentro do app não cai de novo nesta tela.
  void goToApp(BuildContext context) {
    debugPrint('[login] entrando: pushReplacementNamed(${Rotas.app})');
    Navigator.of(context).pushReplacementNamed(Rotas.app);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Início',
                    style: TextStyle(
                      color: Color(0xFFAAA7B3),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const StatusBar(),
                ],
              ),
              const SizedBox(height: 27),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 19,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1725),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Positioned(
                      right: 13,
                      top: 10,
                      child: Container(
                        width: 3,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Códice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Nuvem Assistencial de Visualização Interativa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF77727F),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 29),
              Container(
                width: 143,
                height: 143,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00C5C2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Image(
                    image: frostImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D4C1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'IRIS - guia',
                    style: TextStyle(
                      color: Color(0xFF00D4C1),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Se precisar de alguma ajuda, só\n'
                'clicar em meu ícone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC5C1CB),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => goToApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    foregroundColor: const Color(0xFF0D0B13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'criar meu NAVI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: () => goToApp(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF474252)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'já tenho um códice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 186,
                height: 1,
                color: const Color(0xFF25222D),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
