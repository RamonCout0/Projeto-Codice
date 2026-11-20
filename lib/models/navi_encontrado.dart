import 'package:flutter/material.dart';

/// Um NAVI que o do usuário conheceu na cidade. Tudo aqui vem dos fatos
/// que a NAVICity entrega; nada é escrito à mão.
@immutable
class NaviEncontrado {
  /// Nome que a cidade dá a ele (derivado do id, sem revelar o dono).
  final String nome;

  /// Game master da cidade (como a Iris).
  final bool gm;

  /// 0 a 100, do ponto de vista do NAVI do usuário.
  final int afinidade;

  /// Quantas vezes eles se conheceram ou conversaram.
  final int encontros;

  /// hostil, indiferente ou amistoso.
  final String tom;

  /// "há 12 min", calculado no momento de montar a lista.
  final String quando;
  final String ultimaArea;

  /// O que aconteceu da última vez, em uma frase.
  final String relato;
  final Color cor;

  /// Apelido que o usuário deu; guardado no aparelho.
  final String? apelido;

  const NaviEncontrado({
    required this.nome,
    required this.gm,
    required this.afinidade,
    required this.encontros,
    required this.tom,
    required this.quando,
    required this.ultimaArea,
    required this.relato,
    required this.cor,
    this.apelido,
  });

  String get comoChamar => apelido ?? nome;
}
