import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';

/// Visual dos componentes do Material num lugar só: botões, diálogos,
/// SnackBars e campos já saem com a cara do Códice, sem estilo nas telas.
ThemeData criarTema() {
  final arredondado = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(13),
  );
  const tamanhoBotao = Size.fromHeight(44);
  const textoBotao = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Cores.roxo,
      brightness: Brightness.dark,
      primary: Cores.roxo,
      surface: Cores.painel,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.roxo,
        foregroundColor: Cores.sobreRoxo,
        disabledBackgroundColor: Cores.trilho,
        disabledForegroundColor: const Color(0xFF7D778A),
        elevation: 0,
        minimumSize: tamanhoBotao,
        shape: arredondado,
        textStyle: textoBotao,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Cores.roxo,
        foregroundColor: Cores.sobreRoxo,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: tamanhoBotao,
        side: const BorderSide(color: Cores.bordaForte),
        shape: arredondado,
        textStyle: textoBotao,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.painel,
      titleTextStyle: Estilos.tituloDialogo,
      contentTextStyle: Estilos.corpo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Cores.linha),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cores.roxoFundo,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
      actionTextColor: Cores.roxo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.roxoBorda),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cores.painel,
      showDragHandle: true,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Cores.painel),
    dividerTheme: const DividerThemeData(color: Cores.linha),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Cores.ciano,
      linearTrackColor: Cores.trilho,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Cores.roxo : null,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(color: Cores.texto, fontSize: 13),
      subtitleTextStyle: Estilos.legenda,
    ),
  );
}
