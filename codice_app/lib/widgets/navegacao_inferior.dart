import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/app/abas.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLine, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kBottom,
        elevation: 0,
        iconSize: 17,
        selectedItemColor: kPurple,
        unselectedItemColor: const Color(0xFF898494),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          for (final aba in abas)
            BottomNavigationBarItem(
              icon: Icon(aba.icone),
              // A "pílula" atrás do ícone da aba selecionada.
              activeIcon: Container(
                width: 27,
                height: 23,
                decoration: BoxDecoration(
                  color: const Color(0xFF251B4B),
                  borderRadius: BorderRadius.circular(12),
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
