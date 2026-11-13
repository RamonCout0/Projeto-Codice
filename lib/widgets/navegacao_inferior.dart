import 'package:flutter/material.dart';
import 'package:codice_app/app/abas.dart';
import 'package:codice_app/tema/cores.dart';

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
      child: BottomNavigationBar(
        currentIndex: selecionada,
        onTap: aoSelecionar,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Cores.barra,
        elevation: 0,
        iconSize: 20,
        selectedItemColor: Cores.roxo,
        unselectedItemColor: const Color(0xFF898494),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          for (final aba in abas)
            BottomNavigationBarItem(
              icon: Icon(aba.icone),
              activeIcon: Container(
                width: 32,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF251B4B),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(aba.icone),
              ),
              label: aba.nome,
            ),
        ],
      ),
    );
  }
}
