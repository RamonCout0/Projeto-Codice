import 'package:flutter/material.dart';

/// Paleta única do app, nos dois temas do Figma (noturno e claro). Nenhuma
/// tela declara cor solta: tudo vem daqui.
///
/// As cores são getters que olham [claro]. Quem muda o tema (CodiceApp) ajusta
/// [claro] e manda reconstruir a árvore; por isso nenhum widget guarda uma cor
/// em `const`.
abstract final class Cores {
  /// true = tema claro. Definido pelo CodiceApp (ajuste "Aparência").
  static bool claro = false;

  static Color _c(int escuro, int claroValor) => Color(claro ? claroValor : escuro);

  // Fundos, do mais escuro para o mais claro (no claro, o contrário).
  static Color get fundo => _c(0xFF0E0D15, 0xFFF2F1F8);
  static Color get barra => _c(0xFF14131D, 0xFFFFFFFF);
  static Color get painel => _c(0xFF191824, 0xFFFFFFFF);
  static Color get cartao => _c(0xFF1B1A27, 0xFFFFFFFF);
  static Color get cartaoClaro => _c(0xFF232131, 0xFFF8F7FC);
  static Color get palco => _c(0xFF111624, 0xFFECE9FA);
  static Color get trilho => _c(0xFF2B2745, 0xFFE3E0EE);

  
  // Bordas.
  static Color get linha => _c(0xFF2C2A3C, 0xFFE3E0EE);
  static Color get borda => _c(0xFF2C2A3C, 0xFFE3E0EE);
  static Color get bordaForte => _c(0xFF42405A, 0xFFCFCADF);
  static Color get bordaRoxa => _c(0xFF493A70, 0xFFC9C0F0);

  
  // Roxo (cor principal).
  static Color get roxo => _c(0xFFA292FF, 0xFF5B4BD6);
  static Color get roxoClaro => _c(0xFFBBAEFF, 0xFF5B4BD6);
  static Color get roxoFundo => _c(0xFF241F3C, 0xFFECE9FB);
  static Color get roxoAtivo => _c(0xFF2B2452, 0xFFE1DBF9);
  static Color get roxoBorda => _c(0xFF4A3A76, 0xFFCFC7F5);
  static Color get roxoProfundo => _c(0xFF7A5CF0, 0xFF4A3BC4);
  static Color get sobreRoxo => _c(0xFF14101F, 0xFFFFFFFF);

  
  // Texto.
  static Color get texto => _c(0xFFF3F1FA, 0xFF191826);
  static Color get textoSuave => _c(0xFFD2CEE0, 0xFF3A3752);
  static Color get textoSecundario => _c(0xFFB9B5CC, 0xFF4B4863);
  static Color get textoApagado => _c(0xFF8B87A2, 0xFF6E6A88);
  static Color get textoFraco => _c(0xFF77738D, 0xFF8A86A0);

  
  // Destaques.
  static Color get ciano => _c(0xFF65D6D6, 0xFF0A8C84);
  static Color get turquesa => _c(0xFF00C5C2, 0xFF0F9E98);
  static Color get verde => _c(0xFF4CD8A0, 0xFF12855C);
  static Color get verdeFundo => _c(0xFF07382B, 0xFFDDF3EA);
  static Color get rosa => _c(0xFFFF8FB1, 0xFFD6336C);
  static Color get vermelho => _c(0xFFFF7C6E, 0xFFC43A32);

  
  // Âmbar: usado nas perguntas da NAVI (contradições).
  static Color get ambar => _c(0xFFF0B35C, 0xFFB26A0A);
  static Color get ambarFundo => _c(0xFF2B200F, 0xFFFBF0DC);
  static Color get ambarBorda => _c(0xFF5B411B, 0xFFE8C98F);
  static Color get ambarTexto => _c(0xFFD9CBB4, 0xFF6B4A12);
  static Color get ambarSuave => _c(0xFF9C917E, 0xFF8A6F3F);
  static Color get sobreAmbar => _c(0xFF251A09, 0xFFFFFFFF);
}
