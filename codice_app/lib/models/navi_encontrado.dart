import 'package:flutter/material.dart';

class NaviEncontrado {
  final String nome;
  final int afinidade; // 0 a 100
  final String quando;
  final String relato;
  final Color cor;
  String? apelido;

  NaviEncontrado(
    this.nome,
    this.afinidade,
    this.quando,
    this.relato,
    this.cor,
  );

  String get comoChamar => apelido ?? nome;
}
