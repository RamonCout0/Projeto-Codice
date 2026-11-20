import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/icones.dart';

/// O elemento muda o jeito de ser e de falar do NAVI.
enum Elemento {
  gelo(
    'Gelo',
    Ic.floco,
    Color(0xFF8FE3F0),
    Color(0xFF128299),
    'calma e observadora; fala com frases limpas e precisas, sem exagero, '
        'e gosta de silêncio e de coisas frias',
  ),
  fogo(
    'Fogo',
    Ic.chama,
    Color(0xFFFF5A36),
    Color(0xFFC4351A),
    'animada e intensa; fala com entusiasmo, se empolga fácil e torce '
        'pela pessoa',
  ),
  agua(
    'Água',
    Ic.gota,
    Color(0xFF3D8BFF),
    Color(0xFF1F5FD0),
    'gentil e acolhedora; adapta o tom ao humor da pessoa e gosta mais de '
        'ouvir do que de falar',
  ),
  terra(
    'Terra',
    Ic.montanha,
    Color(0xFF5FC97F),
    Color(0xFF22834A),
    'paciente e prática; fala devagar, gosta de rotina e de coisas '
        'concretas do dia a dia',
  ),
  ar(
    'Ar',
    Ic.vento,
    Color(0xFFC9A7FF),
    Color(0xFF7444DC),
    'leve e distraída; faz perguntas soltas, muda de assunto e adora '
        'novidades',
  ),
  luz(
    'Luz',
    Ic.sol,
    Color(0xFFFFE08A),
    Color(0xFFA67A00),
    'otimista; procura o lado bom das coisas e elogia com sinceridade',
  ),
  sombra(
    'Sombra',
    Ic.lua,
    Color(0xFFA08BD9),
    Color(0xFF5B4A9E),
    'reservada e misteriosa; fala pouco, mas repara em detalhes que '
        'ninguém percebe',
  ),
  eletrico(
    'Elétrico',
    Ic.raio,
    Color(0xFFFFD23F),
    Color(0xFF9C7400),
    'rápida e agitada; pensa alto, junta ideias depressa e adora jogos e '
        'desafios',
  ),
  // Exclusivo dos GMs (como a Iris): o servidor recusa quem tentar se
  // registrar com ele, e a tela de criação não o oferece.
  cyber(
    'Cyber',
    Ic.chip,
    Color(0xFF31DDD2),
    Color(0xFF0A8C84),
    'precisa e analítica; fala como quem enxerga a cidade inteira de cima, '
        'com calma e um toque de ironia',
    soGM: true,
  );

  final String titulo;
  final Ic icone;
  final Color _corNoEscuro;
  final Color _corNoClaro;

  /// A cor do elemento no tema atual: a do Figma no noturno e a versão
  /// "sobre papel" (mais escura, legível) no claro.
  Color get cor => Cores.claro ? _corNoClaro : _corNoEscuro;

  /// Como o Gemma deve interpretar este elemento.
  final String jeito;

  /// Só game masters têm; nenhum jogador pode escolher.
  final bool soGM;
  const Elemento(
    this.titulo,
    this.icone,
    this._corNoEscuro,
    this._corNoClaro,
    this.jeito, {
    this.soGM = false,
  });

  /// Os elementos que a pessoa pode escolher ao criar o NAVI.
  static List<Elemento> get escolhiveis => [
    for (final e in values)
      if (!e.soGM) e,
  ];
}

/// Traços de personalidade: o NAVI tem de 1 a 3.
enum Traco {
  curiosa('curiosa', 'faz perguntas sobre tudo o que a pessoa conta'),
  timida('tímida', 'é um pouco envergonhada e às vezes hesita antes de falar'),
  brincalhona('brincalhona', 'faz piadinhas inocentes e gosta de brincar'),
  carinhosa('carinhosa', 'demonstra afeto e se preocupa com a pessoa'),
  teimosa('teimosa', 'defende as próprias ideias, mas aceita quando aprende'),
  corajosa('corajosa', 'encoraja a pessoa a tentar coisas novas'),
  sonhadora('sonhadora', 'imagina histórias e faz comparações criativas'),
  organizada('organizada', 'gosta de listas, horários e de lembrar compromissos'),
  dramatica('dramática', 'reage com exagero divertido às novidades'),
  calma('calma', 'nunca se apressa e tranquiliza a pessoa');

  final String titulo;

  /// Como o Gemma deve interpretar este traço.
  final String jeito;
  const Traco(this.titulo, this.jeito);
}

/// Quem é o NAVI da pessoa. Fica na conta (API) e numa cópia no aparelho.
@immutable
class PerfilNavi {
  final String nome;
  final Elemento elemento;
  final List<Traco> tracos;
  final String gostos;

  const PerfilNavi({
    required this.nome,
    required this.elemento,
    required this.tracos,
    this.gostos = '',
  });

  /// O NAVI de quem ainda não criou o seu.
  static const padrao = PerfilNavi(
    nome: 'Frost',
    elemento: Elemento.gelo,
    tracos: [Traco.curiosa, Traco.carinhosa],
    gostos: 'ler o diário e neve',
  );

  static const maxTracos = 3;
  static const maxNome = 20;
  static const maxGostos = 140;

  PerfilNavi copiar({
    String? nome,
    Elemento? elemento,
    List<Traco>? tracos,
    String? gostos,
  }) => PerfilNavi(
    nome: nome ?? this.nome,
    elemento: elemento ?? this.elemento,
    tracos: tracos ?? this.tracos,
    gostos: gostos ?? this.gostos,
  );

  Map<String, Object> toJson() => {
    'nome': nome,
    'elemento': elemento.name,
    'tracos': [for (final t in tracos) t.name],
    'gostos': gostos,
  };

  /// Null se faltar algo ou vier um valor desconhecido.
  static PerfilNavi? fromJson(Object? dados) {
    if (dados case {
      'nome': String nome,
      'elemento': String elemento,
      'tracos': List<dynamic> tracos,
    }) {
      final e = Elemento.values.where((v) => v.name == elemento).firstOrNull;
      final t = [
        for (final nomeTraco in tracos)
          ...Traco.values.where((v) => v.name == nomeTraco),
      ];
      if (e == null || t.isEmpty || nome.trim().isEmpty) return null;
      final gostos = dados['gostos'] is String ? dados['gostos'] as String : '';
      return PerfilNavi(
        nome: nome.trim(),
        elemento: e,
        tracos: t.take(maxTracos).toList(),
        gostos: gostos,
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PerfilNavi &&
      other.nome == nome &&
      other.elemento == elemento &&
      other.gostos == gostos &&
      other.tracos.length == tracos.length &&
      Iterable.generate(tracos.length).every((i) => other.tracos[i] == tracos[i]);

  @override
  int get hashCode => Object.hash(nome, elemento, gostos, Object.hashAll(tracos));
}
