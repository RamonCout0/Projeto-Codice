import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';

/// Visual dos componentes do Material num lugar só: botões, diálogos,
/// SnackBars e campos já saem com a cara do Códice, sem estilo nas telas.
ThemeData criarTema() {
  final arredondado = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  const tamanhoBotao = Size.fromHeight(50);
  const textoBotao = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Cores.fundo,
    // Transições suaves e iguais em todas as plataformas.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
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
        minimumSize: tamanhoBotao,
        shape: arredondado,
        textStyle: textoBotao,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Cores.roxoClaro,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.fundo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.painel,
      labelStyle: const TextStyle(color: Cores.textoApagado, fontSize: 14),
      hintStyle: const TextStyle(color: Cores.textoFraco, fontSize: 14),
      prefixIconColor: Cores.textoApagado,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cores.roxo, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cores.vermelho),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Cores.vermelho, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Cores.painel,
      selectedColor: Cores.roxoAtivo,
      side: const BorderSide(color: Cores.borda),
      labelStyle: const TextStyle(color: Cores.textoSuave, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      checkmarkColor: Cores.roxoClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Cores.roxo : null,
      ),
      checkColor: const WidgetStatePropertyAll(Cores.sobreRoxo),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Cores.linha),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cores.roxoFundo,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: Cores.roxo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Cores.roxoBorda),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cores.painel,
      showDragHandle: true,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Cores.painel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected)
              ? Cores.roxoClaro
              : Cores.textoApagado,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    ),
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
      titleTextStyle: TextStyle(color: Cores.texto, fontSize: 15, fontWeight: FontWeight.w600),
      subtitleTextStyle: Estilos.legenda,
    ),
  );
}
