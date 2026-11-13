import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/avatar_navi.dart';

class BoasVindasTela extends StatelessWidget {
  const BoasVindasTela({super.key});

  /// pushReplacement: o voltar do Android dentro do app não cai aqui.
  void _entrar(BuildContext context) =>
      Navigator.of(context).pushReplacementNamed(Rotas.app);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
          child: Column(
            children: [
              const _Logo(),
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
                style: TextStyle(color: Color(0xFF77727F), fontSize: 10),
              ),
              const SizedBox(height: 29),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Cores.turquesa),
                ),
                child: const AvatarNavi(
                  largura: 150,
                  altura: 150,
                  redondo: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '● IRIS - guia',
                style: TextStyle(
                  color: Color(0xFF00D4C1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se precisar de alguma ajuda, só\nclicar em meu ícone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoSuave, fontSize: 11),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _entrar(context),
                child: const Text('criar meu NAVI'),
              ),
              const SizedBox(height: 9),
              OutlinedButton(
                onPressed: () => _entrar(context),
                child: const Text('já tenho um códice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ícone do Códice: um caderno com um marcador.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Cores.roxo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        width: 19,
        height: 28,
        alignment: const Alignment(0.5, -0.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1725),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Container(width: 3, height: 8, color: Cores.roxo),
      ),
    );
  }
}
