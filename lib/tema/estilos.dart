import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

/// Tipografia e medidas repetidas pelas telas. A escala foi aumentada em
/// relação à primeira versão (textos de 9 a 12 eram pequenos demais para
/// ler no celular): corpo 14, legenda 12, rótulos 11.
abstract final class Estilos {
  static TextStyle get titulo => TextStyle(fontFamily: 'Inter', 
    color: Cores.texto,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.15,
  );
  static TextStyle get tituloDialogo => TextStyle(fontFamily: 'Inter', 
    color: Cores.texto,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static TextStyle get cabecalho => TextStyle(fontFamily: 'Inter', 
    color: Cores.texto,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );
  static TextStyle get corpo => TextStyle(fontFamily: 'Inter', color: Cores.texto, fontSize: 14, height: 1.45);
  static TextStyle get corpoSuave => TextStyle(fontFamily: 'Inter', 
    color: Cores.textoSuave,
    fontSize: 14,
    height: 1.5,
  );
  static TextStyle get legenda => TextStyle(fontFamily: 'Inter', 
    color: Cores.textoApagado,
    fontSize: 12,
    height: 1.35,
  );
  static TextStyle get rotulo => TextStyle(fontFamily: 'Inter', 
    color: Cores.textoApagado,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get secao => TextStyle(fontFamily: 'Inter', 
    color: Cores.textoApagado,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  static const margem = 20.0;
  static const raio = 20.0;
}
