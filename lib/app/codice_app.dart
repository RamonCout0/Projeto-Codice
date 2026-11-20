import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/moldura.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/tema.dart';

/// Raiz visual do app. Também decide o tema (noturno ou claro): as cores são
/// getters que olham `Cores.claro`, então, ao trocar, a árvore inteira é
/// marcada para reconstruir, sem perder a tela em que a pessoa está.
class CodiceApp extends StatefulWidget {
  const CodiceApp({super.key});

  @override
  State<CodiceApp> createState() => _CodiceAppState();
}

class _CodiceAppState extends State<CodiceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// O aparelho trocou entre claro e escuro (vale se o modo for "sistema").
  @override
  void didChangePlatformBrightness() => setState(() {});

  static void _reconstruir(Element e) {
    e.markNeedsBuild();
    e.visitChildren(_reconstruir);
  }

  @override
  Widget build(BuildContext context) {
    final modo = context.watch<Ajustes>().modoTema;
    final claro = switch (modo) {
      ModoTema.claro => true,
      ModoTema.escuro => false,
      ModoTema.sistema => PlatformDispatcher.instance.platformBrightness == Brightness.light,
    };
    if (claro != Cores.claro) {
      Cores.claro = claro;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.rootElement?.visitChildren(_reconstruir);
      });
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Códice',
      theme: criarTema(),
      // A moldura embrulha o Navigator: diálogos e SnackBars ficam dentro
      // do "celular" quando o app roda no PC.
      builder: (context, child) => Moldura(child: child!),
      initialRoute: Rotas.inicio,
      routes: Rotas.mapa,
      onGenerateRoute: Rotas.gerar,
    );
  }
}
