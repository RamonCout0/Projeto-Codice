import 'package:flutter/material.dart';
import 'package:codice_app/services/api_navicity.dart';

/// Um lugar da NAVICity, como a cidade o descreve agora.
class Lugar {
  final int id;
  final String nome;

  /// praca, biblioteca ou cafe: o desenho do lugar vem daqui.
  final String tipo;
  final int presentes;

  /// O NAVI do usuário está aqui agora.
  final bool voce;

  const Lugar({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.presentes,
    required this.voce,
  });

  factory Lugar.daArea(AreaDaCidade a) => Lugar(
    id: a.id,
    nome: a.nome,
    tipo: a.tipo,
    presentes: a.presentes,
    voce: a.voce,
  );

  IconData get icone => switch (tipo) {
    'praca' => Icons.graphic_eq,
    'biblioteca' => Icons.local_library_outlined,
    'cafe' => Icons.local_cafe_outlined,
    _ => Icons.place_outlined,
  };

  /// Resumo do que acontece aqui agora, tirado dos números da cidade.
  String get descricao {
    final gente = switch (presentes) {
      0 => 'Ninguém por aqui agora',
      1 => '1 NAVI aqui agora',
      _ => '$presentes NAVIs aqui agora',
    };
    return voce ? '$gente, incluindo o seu.' : '$gente.';
  }
}
