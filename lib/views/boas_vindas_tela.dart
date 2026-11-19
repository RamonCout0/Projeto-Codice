import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/basicos.dart';

class BoasVindasTela extends StatefulWidget {
  const BoasVindasTela({super.key});

  @override
  State<BoasVindasTela> createState() => _BoasVindasTelaState();
}

class _BoasVindasTelaState extends State<BoasVindasTela> {
  @override
  void initState() {
    super.initState();
    // "manter conectado" da última vez: vai direto para o NAVI.
    context.read<Sessao>().restaurada.then((recuperada) {
      if (!recuperada || !mounted) return;
      avisar(
        context,
        'sessão recuperada do armazenamento seguro',
        icone: Icons.lock_outline,
      );
      Navigator.of(context).pushReplacementNamed(Rotas.app);
    });
  }

  /// Criar conta ou entrar pela sessão segura (registro e login JWT).
  /// Lá também dá para seguir sem conta.
  void _abrirSessao({required bool criarConta}) =>
      Navigator.of(context).pushNamed(Rotas.sessao, arguments: criarConta);

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<Sessao>();
    final cor = sessao.perfil.elemento.cor;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 0.9,
            colors: [Color(0xFF1E1934), Cores.fundo],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
            child: Column(
              children: [
                const _Logo(),
                const SizedBox(height: 10),
                const Text(
                  'Códice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Nuvem Assistencial de Visualização Interativa',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoApagado, fontSize: 10),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cor.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: cor.withValues(alpha: 0.28),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const AvatarNavi(largura: 150, altura: 150, redondo: true),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Cores.turquesa),
                    const SizedBox(width: 6),
                    const Text(
                      'IRIS · guia',
                      style: TextStyle(
                        color: Cores.turquesa,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'um diário onde uma criatura digital\naprende com a convivência.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoSuave, fontSize: 12, height: 1.45),
                ),
                const Spacer(flex: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: sessao.restaurando
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Column(
                          key: const ValueKey('botoes'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () => _abrirSessao(criarConta: true),
                              child: const Text('criar meu NAVI'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => _abrirSessao(criarConta: false),
                              child: const Text('já tenho um códice'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
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
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.roxoClaro, Color(0xFF7A5CF0)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Cores.roxo.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        width: 20,
        height: 29,
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
