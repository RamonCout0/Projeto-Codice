import 'package:flutter/material.dart';
import 'package:codice_app/app/moldura.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/tema/tema.dart';

class CodiceApp extends StatelessWidget {
  const CodiceApp({super.key});

  @override
  Widget build(BuildContext context) {
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
