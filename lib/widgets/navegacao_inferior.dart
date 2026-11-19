import 'package:flutter/material.dart';
import 'package:codice_app/app/abas.dart';
import 'package:codice_app/tema/cores.dart';

/// Barra das abas (Material 3): a aba aberta ganha uma pílula roxa.
class NavegacaoInferior extends StatelessWidget {
  final int selecionada;
  final ValueChanged<int> aoSelecionar;

  const NavegacaoInferior({
    super.key,
    required this.selecionada,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Cores.linha)),
      ),
      child: NavigationBar(
        selectedIndex: selecionada,
        onDestinationSelected: aoSelecionar,
        height: 62,
        backgroundColor: Cores.barra,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Cores.roxoAtivo,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final aba in abas)
            NavigationDestination(
              icon: Icon(aba.icone, color: Cores.textoApagado, size: 21),
              selectedIcon: Icon(aba.icone, color: Cores.roxoClaro, size: 21),
              label: aba.nome,
            ),
        ],
      ),
    );
  }
}
