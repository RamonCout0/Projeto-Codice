import 'package:flutter/material.dart';

/// Paleta única do app. Nenhuma tela declara cor solta: tudo vem daqui.
abstract final class Cores {
  // Fundos, do mais escuro para o mais claro.
  static const fundo = Color(0xFF0E0D15);
  static const barra = Color(0xFF12101B);
  static const painel = Color(0xFF171521);
  static const cartao = Color(0xFF1A1924);
  static const cartaoClaro = Color(0xFF211F2B);
  static const palco = Color(0xFF111624);
  static const trilho = Color(0xFF2A2640);

  // Bordas.
  static const linha = Color(0xFF302B3C);
  static const borda = Color(0xFF302D3B);
  static const bordaForte = Color(0xFF474252);

  // Roxo (cor principal).
  static const roxo = Color(0xFF9B82FF);
  static const roxoClaro = Color(0xFFAA91FF);
  static const roxoFundo = Color(0xFF211B3A);
  static const roxoAtivo = Color(0xFF241D40);
  static const roxoBorda = Color(0xFF4A3A76);
  static const sobreRoxo = Color(0xFF171322);

  // Texto.
  static const texto = Color(0xFFE4E0E9);
  static const textoSuave = Color(0xFFC5C1CB);
  static const textoSecundario = Color(0xFFB8B2C5);
  static const textoApagado = Color(0xFF8B8498);
  static const textoFraco = Color(0xFF6F6A7C);

  // Destaques.
  static const ciano = Color(0xFF65D6D6);
  static const turquesa = Color(0xFF00C5C2);
  static const verde = Color(0xFF52D9A2);
  static const verdeFundo = Color(0xFF07382B);
  static const rosa = Color(0xFFFF8FB1);
  static const vermelho = Color(0xFFFF8A8A);

  // Âmbar: usado nas perguntas da NAVI (contradições).
  static const ambar = Color(0xFFF0B74B);
  static const ambarFundo = Color(0xFF36250D);
  static const ambarBorda = Color(0xFF5B411B);
  static const ambarTexto = Color(0xFFD9CBB4);
  static const sobreAmbar = Color(0xFF251A09);
}
