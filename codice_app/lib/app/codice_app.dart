import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/app/observador_da_pilha.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/ui/moldura.dart';

class CodiceApp extends StatefulWidget {
  const CodiceApp({super.key});

  @override
  State<CodiceApp> createState() => _CodiceAppState();
}

class _CodiceAppState extends State<CodiceApp> {
  /// Imprime no console cada push/pop da pilha raiz (login, app,
  /// configurações e diálogos).
  final ObservadorDaPilha _observadorRaiz = ObservadorDaPilha('raiz');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Códice',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPurple,
          brightness: Brightness.dark,
        ),
      ),
      // A moldura embrulha o Navigator inteiro: assim a troca de tela,
      // os AlertDialogs, as SnackBars e o bottom sheet acontecem DENTRO
      // do "celular", em vez de escaparem para a janela toda.
      builder: (context, child) => PhoneFrame(child: child!),
      // Rotas nomeadas centralizadas: as telas sem parâmetro ficam no
      // mapa; as que recebem arguments passam pelo Rotas.gerar.
      initialRoute: Rotas.login,
      routes: Rotas.mapa,
      onGenerateRoute: Rotas.gerar,
      navigatorObservers: [_observadorRaiz],
    );
  }
}
