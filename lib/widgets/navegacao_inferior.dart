import 'package:flutter/material.dart';
import 'package:codice_app/app/abas.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/widgets/icones.dart';

/// Barra das abas flutuante: uma cápsula com cantos bem arredondados que
/// "descola" do fundo; a aba aberta ganha uma pílula roxa.
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
    final forma = BorderRadius.circular(28);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Cores.barra,
          borderRadius: forma,
          border: Border.all(color: Cores.linha),
          boxShadow: Efeitos.sombraCartao,
        ),
        child: ClipRRect(
          borderRadius: forma,
          child: NavigationBar(
            selectedIndex: selecionada,
            onDestinationSelected: aoSelecionar,
            height: 66,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Cores.roxoAtivo,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final aba in abas)
                NavigationDestination(
                  icon: IconeCodice(aba.icone, color: Cores.textoApagado, size: 23),
                  selectedIcon: IconeCodice(aba.icone, color: Cores.roxoClaro, size: 23),
                  label: aba.nome,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
