import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Tipografia e medidas repetidas pelas telas.
abstract final class Estilos {
  static const titulo = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const tituloDialogo = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const cabecalho = TextStyle(color: Color(0xFF8D8996), fontSize: 14);
  static const corpo = TextStyle(color: Cores.texto, fontSize: 12, height: 1.4);
  static const corpoSuave = TextStyle(
    color: Cores.textoSuave,
    fontSize: 12,
    height: 1.45,
  );
  static const legenda = TextStyle(color: Cores.textoApagado, fontSize: 10);
  static const rotulo = TextStyle(
    color: Cores.textoApagado,
    fontSize: 9,
    fontWeight: FontWeight.bold,
  );
  static const secao = TextStyle(
    color: Cores.textoApagado,
    fontSize: 9,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static const margem = 16.0;
  static const raio = 15.0;
}
