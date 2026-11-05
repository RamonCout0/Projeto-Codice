import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/models/navi_encontrado.dart';

class EstadoCodice extends ChangeNotifier {
  final List<NaviEncontrado> _navis = [
    NaviEncontrado(
      'Pixel',
      72,
      'hoje, 14:20 · Praça dos Bipes',
      'Pixel fala rápido e repete os bipes de três em três. A Frost achou '
          'engraçado e quer encontrar de novo.',
      const Color(0xFF6CEFF1),
    ),
    NaviEncontrado(
      'Bolota',
      45,
      'ontem, 19:05 · Café da Esquina',
      'Bolota ficou quieto quase o encontro todo. A Frost acha que ele é '
          'tímido, não chato.',
      const Color(0xFFFFB86B),
    ),
    NaviEncontrado(
      'Nimbus',
      88,
      'segunda, 08:40 · Biblioteca Velha',
      'Nimbus também gosta de ler. Os dois trocaram bipes longos, que no '
          'Navidês é sinal de amizade.',
      kPurple,
    ),
  ];

  List<NaviEncontrado> get navis => List.unmodifiable(_navis);

  NaviEncontrado? obterNavi(String nome) {
    for (final navi in _navis) {
      if (navi.nome == nome) return navi;
    }
    return null;
  }

  void alterarApelido(String nome, String novoApelido) {
    final navi = obterNavi(nome);
    if (navi == null || novoApelido.trim().isEmpty) return;

    navi.apelido = novoApelido.trim();
    notifyListeners();
  }
}
