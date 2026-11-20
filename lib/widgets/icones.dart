import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:codice_app/tema/cores.dart';

/// Ícones vetoriais próprios do Códice (assets/icones/*.svg), desenhados para
/// o projeto: traço arredondado e pequenos "bips" como assinatura. O app
/// pinta cada um com a cor do tema.
enum Ic {
  acenar,
  ajuda,
  ampulheta,
  apagar,
  arquivoAbrir('arquivo_abrir'),
  balaoNavi('balao_navi'),
  biblioteca,
  bloquear,
  bolo,
  cadeado,
  cafe,
  caminhar,
  check,
  checkCirculo('check_circulo'),
  chip,
  cidade,
  circulo,
  circuloCheio('circulo_cheio'),
  config,
  conversa,
  coracao,
  coracaoCheio('coracao_cheio'),
  cracha,
  cubo,
  diario,
  editar,
  chama('el_chama'),
  cyber('el_cyber'),
  floco('el_floco'),
  gota('el_gota'),
  lua('el_lua'),
  montanha('el_montanha'),
  raio('el_raio'),
  sol('el_sol'),
  vento('el_vento'),
  encontros,
  enviar,
  erro,
  escrever,
  escudoOk('escudo_ok'),
  fechar,
  gm,
  historico,
  info,
  lampada,
  livroAberto('livro_aberto'),
  lugar,
  mais,
  maisHoriz('mais_horiz'),
  marcador,
  marcadorOk('marcador_ok'),
  marcadores,
  menu,
  navi,
  nuvem,
  nuvemOff('nuvem_off'),
  pessoaMais('pessoa_mais'),
  pessoas,
  praca,
  robo,
  sair,
  setaDir('seta_dir'),
  sync,
  toque,
  troca,
  voltar,
  wifiOff('wifi_off');

  const Ic([this._arquivo]);
  final String? _arquivo;

  String get caminho => 'assets/icones/${_arquivo ?? name}.svg';
}

/// Desenha um [Ic]. Mesma assinatura do `Icon` do Material (ícone, color,
/// size), para trocar um pelo outro sem mexer nas telas.
class IconeCodice extends StatelessWidget {
  final Ic icone;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  const IconeCodice(this.icone, {super.key, this.color, this.size, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final tamanho = size ?? tema.size ?? 24;
    final cor = color ?? tema.color ?? Cores.texto;
    return SvgPicture.asset(
      icone.caminho,
      width: tamanho,
      height: tamanho,
      colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
