import 'package:codice_app/services/api_navicity.dart';

/// Transforma fatos da cidade em frases. O servidor só entrega dados
/// estruturados; quem conta a história é o app (e, na conversa, o Gemma).

String tomEmTexto(String? tom) => switch (tom) {
  'hostil' => 'hostil',
  'amistoso' => 'amistosa',
  _ => 'indiferente',
};

/// "agora", "há 5 min", "há 3 h", "há 2 dias".
String haQuanto(int segundos) {
  if (segundos < 60) return 'agora';
  final min = segundos ~/ 60;
  if (min < 60) return 'há $min min';
  final h = min ~/ 60;
  if (h < 24) return 'há $h h';
  final d = h ~/ 24;
  return d == 1 ? 'há 1 dia' : 'há $d dias';
}

/// Uma frase sobre o fato, do ponto de vista do NAVI do usuário.
String narrar(FatoDaCidade f, String meuNome) {
  final outro = f.outro ?? 'alguém';
  final origem = f.lado != 'alvo';
  return switch (f.tipo) {
    'entrou' => '$meuNome chegou à NAVICity.',
    'partiu' => '$meuNome saiu rumo a ${f.destino ?? 'outro lugar'}.',
    'chegou' => '$meuNome chegou em ${f.area}.',
    'conheceu' =>
      origem
          ? '$meuNome puxou conversa e conheceu $outro em ${f.area}.'
          : '$outro puxou conversa com $meuNome em ${f.area}. Eles se conheceram.',
    'conversou' =>
      '$meuNome e $outro conversaram em ${f.area}'
          '${f.afinidade == null ? '' : ' · afinidade ${f.afinidade}%'}'
          '${f.delta == null || f.delta == 0 ? '' : ' (${f.delta! > 0 ? '+' : ''}${f.delta})'}.',
    'recusou' =>
      origem
          ? '$outro não quis conversar com $meuNome.'
          : '$meuNome não quis conversar com $outro.',
    'mudou_tom' =>
      '$meuNome agora acha a relação com $outro ${tomEmTexto(f.tom)}.',
    _ => 'Algo aconteceu em ${f.area}.',
  };
}
