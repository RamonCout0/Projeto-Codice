import 'package:flutter/material.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/icones.dart';

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

  Ic get icone => switch (this) {
    Humor.esperando => Ic.maisHoriz,
    Humor.lendo => Ic.livroAberto,
    Humor.curiosa => Ic.lampada,
    Humor.feliz => Ic.coracaoCheio,
    Humor.confusa => Ic.ajuda,
    Humor.pensando => Ic.navi,
  };
}
