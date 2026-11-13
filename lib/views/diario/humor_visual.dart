import 'package:flutter/material.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/tema/cores.dart';

/// Cor da borda e ícone do balão para cada humor.
extension HumorVisual on Humor {
  Color get cor => switch (this) {
    Humor.esperando => Cores.borda,
    Humor.lendo => Cores.roxo,
    Humor.curiosa => Cores.ciano,
    Humor.feliz => Cores.rosa,
    Humor.confusa => Cores.ambar,
    Humor.pensando => Cores.textoApagado,
  };

  IconData get icone => switch (this) {
    Humor.esperando => Icons.more_horiz,
    Humor.lendo => Icons.menu_book_outlined,
    Humor.curiosa => Icons.lightbulb_outline,
    Humor.feliz => Icons.favorite,
    Humor.confusa => Icons.help_outline,
    Humor.pensando => Icons.psychology_outlined,
  };
}
