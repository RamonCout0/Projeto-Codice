import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/abas.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/navegacao_inferior.dart';

/// Estrutura com as abas. Cada aba tem seu próprio Navigator, e o
/// IndexedStack mantém todos vivos: a pilha de cada aba é preservada.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _navegadores = [for (final _ in abas) GlobalKey<NavigatorState>()];

  int get _aba => context.read<NavegacaoAbas>().aba;

  NavigatorState? get _navegadorAtual => _navegadores[_aba].currentState;

  @override
  void initState() {
    super.initState();
    // Entra na NAVICity com o NAVI da conta (ou do aparelho, sem conta).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sessao = context.read<Sessao>();
      context.read<CidadeNavi>().conectar(
        sessao.perfil,
        conta: sessao.usuario ?? 'local',
      );
    });
  }

  void _trocarAba(int indice) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (indice == _aba) {
      // Tocar de novo na aba aberta volta para a raiz dela.
      _navegadorAtual?.popUntil((rota) => rota.isFirst);
    } else {
      context.read<NavegacaoAbas>().irPara(indice);
    }
  }

  /// Botão voltar do Android: fecha o menu → volta dentro da aba →
  /// vai para a aba Navi → fecha o app.
  void _voltar() {
    final scaffold = _scaffold.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    } else if (_navegadorAtual?.canPop() ?? false) {
      _navegadorAtual!.maybePop();
    } else if (_aba != 0) {
      _trocarAba(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aba = context.watch<NavegacaoAbas>().aba;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _voltar();
      },
      child: Scaffold(
        key: _scaffold,
        drawer: const MenuLateral(),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: aba,
            children: [
              for (var i = 0; i < abas.length; i++)
                Navigator(
                  key: _navegadores[i],
                  onGenerateInitialRoutes: (_, _) => [
                    Rotas.gerar(RouteSettings(name: abas[i].rota))!,
                  ],
                  onGenerateRoute: Rotas.gerar,
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavegacaoInferior(selecionada: aba, aoSelecionar: _trocarAba),
        ),
      ),
    );
  }
}
