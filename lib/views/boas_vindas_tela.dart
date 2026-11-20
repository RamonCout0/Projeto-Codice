import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/ambiente.dart';
import 'package:codice_app/widgets/foto_navi.dart';
import 'package:codice_app/widgets/icones.dart';
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
        icone: Ic.cadeado,
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
    final cyber = Elemento.cyber.cor;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FundoAmbiente()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  SvgPicture.asset('assets/arte/logo.svg', width: 88, height: 88),
                  const SizedBox(height: 14),
                  Text(
                    'Códice',
                    style: Estilos.titulo.copyWith(fontSize: 44, letterSpacing: -1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nuvem Assistencial de Visualização Interativa',
                    textAlign: TextAlign.center,
                    style: Estilos.legenda.copyWith(fontSize: 12.5),
                  ),
                  const Spacer(),
                  // A Iris, GM da cidade, recebe quem chega.
                  FotoNavi(cor: cyber, gm: true, tamanho: 176, redonda: true, humor: Humor.feliz),
                  const SizedBox(height: 18),
                  Pilula(
                    'IRIS · GM da cidade',
                    icone: Ic.gm,
                    cor: cyber,
                    fundo: cyber.withValues(alpha: 0.12),
                    borda: cyber.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'um diário onde uma criatura digital\naprende com a convivência.',
                    textAlign: TextAlign.center,
                    style: Estilos.corpoSuave.copyWith(height: 1.5),
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
        ],
      ),
    );
  }
}
