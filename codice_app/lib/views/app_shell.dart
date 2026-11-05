import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/app/observador_da_pilha.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/app/abas.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/navegacao_inferior.dart';

class AppShell extends StatefulWidget {
  final int abaInicial;

  const AppShell({super.key, this.abaInicial = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int selectedIndex = widget.abaInicial;

  final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();

  /// Um Navigator por aba. O IndexedStack mantém todos vivos, então a
  /// pilha de cada um continua lá quando a pessoa troca de aba.
  final List<GlobalKey<NavigatorState>> _navegadores = [
    for (final _ in abas) GlobalKey<NavigatorState>(),
  ];

  final List<ObservadorDaPilha> _observadores = [
    for (final aba in abas) ObservadorDaPilha(aba.nome),
  ];

  NavigatorState? get _navegadorAtual =>
      _navegadores[selectedIndex].currentState;

  void _trocarAba(int index) {
    // Trocar de aba some com o aviso da aba anterior.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (index == selectedIndex) {
      // Tocar de novo na aba aberta volta para a raiz dela.
      debugPrint('[abas] ${abas[index].nome} de novo: popUntil(raiz)');
      _navegadorAtual?.popUntil((rota) => rota.isFirst);
      return;
    }
    debugPrint('[abas] ${abas[selectedIndex].nome} -> ${abas[index].nome}'
        '  (pilha preservada: [${_observadores[index].pilha}])');
    setState(() => selectedIndex = index);
  }

  /// Botão voltar do sistema. Ele chega no Navigator RAIZ, que não sabe
  /// nada das pilhas das abas; o PopScope intercepta e a decisão é aqui:
  /// 1. Drawer aberto: fecha o Drawer.
  /// 2. A aba tem histórico: pop dentro da própria aba.
  /// 3. A aba está na raiz: volta para a aba Navi.
  /// 4. Já está na raiz da Navi: fecha o app.
  void _voltar() {
    final scaffold = _scaffold.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      debugPrint('[voltar] fecha o Drawer');
      scaffold.closeDrawer();
      return;
    }
    final navegador = _navegadorAtual;
    if (navegador != null && navegador.canPop()) {
      debugPrint('[voltar] pop na pilha da aba ${abas[selectedIndex].nome}');
      navegador.maybePop();
      return;
    }
    if (selectedIndex != 0) {
      debugPrint('[voltar] ${abas[selectedIndex].nome} já está na raiz: '
          'vai para a aba Navi');
      _trocarAba(0);
      return;
    }
    debugPrint('[voltar] raiz da aba Navi: fecha o app');
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        key: _scaffold,
        backgroundColor: kBg,
        drawer: const MenuLateral(),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: selectedIndex,
            children: [
              for (var i = 0; i < abas.length; i++)
                Navigator(
                  key: _navegadores[i],
                  observers: [_observadores[i]],
                  onGenerateInitialRoutes: (_, _) => [
                    Rotas.gerar(RouteSettings(name: abas[i].rota))!,
                  ],
                  onGenerateRoute: Rotas.gerar,
                ),
            ],
          ),
        ),
        // No slot próprio do Scaffold, as SnackBars flutuam ACIMA da barra
        // em vez de cobrirem a navegação.
        bottomNavigationBar: SafeArea(
          top: false,
          child: BottomNavigation(
            selectedIndex: selectedIndex,
            onSelected: _trocarAba,
          ),
        ),
      ),
    );
  }
}
