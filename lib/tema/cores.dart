import 'package:flutter/material.dart';

/// Paleta única do app (tema noturno do Figma). Nenhuma tela declara cor
/// solta: tudo vem daqui.
abstract final class Cores {
  // Fundos, do mais escuro para o mais claro.
  static const fundo = Color(0xFF0E0D15);
  static const barra = Color(0xFF14131D);
  static const painel = Color(0xFF191824);
  static const cartao = Color(0xFF1B1A27);
  static const cartaoClaro = Color(0xFF232131);
  static const palco = Color(0xFF111624);
  static const trilho = Color(0xFF2B2745);

  // Bordas.
  static const linha = Color(0xFF2C2A3C);
  static const borda = Color(0xFF2C2A3C);
  static const bordaForte = Color(0xFF42405A);
  static const bordaRoxa = Color(0xFF493A70);

  // Roxo (cor principal).
  static const roxo = Color(0xFFA292FF);
  static const roxoClaro = Color(0xFFBBAEFF);
  static const roxoFundo = Color(0xFF241F3C);
  static const roxoAtivo = Color(0xFF2B2452);
  static const roxoBorda = Color(0xFF4A3A76);
  static const roxoProfundo = Color(0xFF7A5CF0);
  static const sobreRoxo = Color(0xFF14101F);

  // Texto.
  static const texto = Color(0xFFF3F1FA);
  static const textoSuave = Color(0xFFD2CEE0);
  static const textoSecundario = Color(0xFFB9B5CC);
  static const textoApagado = Color(0xFF8B87A2);
  static const textoFraco = Color(0xFF77738D);

  // Destaques.
  static const ciano = Color(0xFF65D6D6);
  static const turquesa = Color(0xFF00C5C2);
  static const verde = Color(0xFF4CD8A0);
  static const verdeFundo = Color(0xFF07382B);
  static const rosa = Color(0xFFFF8FB1);
  static const vermelho = Color(0xFFFF7C6E);

  // Âmbar: usado nas perguntas da NAVI (contradições).
  static const ambar = Color(0xFFF0B35C);
  static const ambarFundo = Color(0xFF2B200F);
  static const ambarBorda = Color(0xFF5B411B);
  static const ambarTexto = Color(0xFFD9CBB4);
  static const ambarSuave = Color(0xFF9C917E);
  static const sobreAmbar = Color(0xFF251A09);
}
