import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Tipografia e medidas repetidas pelas telas. A escala foi aumentada em
/// relação à primeira versão (textos de 9 a 12 eram pequenos demais para
/// ler no celular): corpo 14, legenda 12, rótulos 11.
abstract final class Estilos {
  static const titulo = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.15,
  );
  static const tituloDialogo = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const cabecalho = TextStyle(
    color: Cores.texto,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );
  static const corpo = TextStyle(color: Cores.texto, fontSize: 14, height: 1.45);
  static const corpoSuave = TextStyle(
    color: Cores.textoSuave,
    fontSize: 14,
    height: 1.5,
  );
  static const legenda = TextStyle(
    color: Cores.textoApagado,
    fontSize: 12,
    height: 1.35,
  );
  static const rotulo = TextStyle(
    color: Cores.textoApagado,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const secao = TextStyle(
    color: Cores.textoApagado,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  static const margem = 20.0;
  static const raio = 20.0;
}
