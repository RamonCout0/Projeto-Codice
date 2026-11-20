import 'package:codice_app/services/api_navicity.dart';
import 'package:codice_app/widgets/icones.dart';

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

  Ic get icone => switch (tipo) {
    'praca' => Ic.praca,
    'biblioteca' => Ic.biblioteca,
    'cafe' => Ic.cafe,
    _ => Ic.lugar,
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
