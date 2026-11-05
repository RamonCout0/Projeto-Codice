import 'package:flutter/material.dart';
import 'package:codice_app/views/boas_vindas.dart';
import 'package:codice_app/views/app_shell.dart';
import 'package:codice_app/views/configuracoes.dart';
import 'package:codice_app/views/home.dart';
import 'package:codice_app/views/conversa.dart';
import 'package:codice_app/views/diario.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/views/cidade.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/views/encontros.dart';
import 'package:codice_app/views/detalhe_navi.dart';
import 'package:codice_app/views/apelido.dart';

class Rotas {
  Rotas._();

  static const String login = '/';
  static const String app = '/app';
  static const String configuracoes = '/configuracoes';

  static const String navi = '/navi';
  static const String conversa = '/conversa';
  static const String diario = '/diario';
  static const String cidade = '/cidade';
  static const String lugar = '/cidade/lugar';
  static const String encontros = '/encontros';
  static const String naviEncontrado = '/encontros/navi';
  static const String apelido = '/encontros/apelido';

  /// Mapa entregue ao MaterialApp.routes.
  static final Map<String, WidgetBuilder> mapa = {
    login: (_) => const WelcomeScreen(),
    app: (_) => const AppShell(),
    configuracoes: (_) => const ConfiguracoesScreen(),
  };

  /// Usado pelo MaterialApp.onGenerateRoute e pelos Navigators de cada
  /// aba. É aqui que os arguments viram parâmetros das telas.
  static Route<dynamic>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case navi:
        return _pagina(settings, const HomeScreen());
      case conversa:
        return _pagina(settings, const ConversationScreen());
      case diario:
        return _pagina(settings, const DiaryScreen());
      case cidade:
        return _pagina(settings, const CityScreen());
      case lugar:
        return _pagina(settings, LugarScreen(lugar: args as Lugar));
      case encontros:
        return _pagina(settings, const MeetingsScreen());
      case naviEncontrado:
        return _pagina(settings, NaviScreen(navi: args as NaviEncontrado));
      case apelido:
        // Tipada como <String>: quem chama faz pushNamed<String> e
        // recebe o apelido de volta. Uma MaterialPageRoute<dynamic>
        // aqui quebraria o cast dentro do pushNamed<String>.
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (_) => ApelidoScreen(apelidoAtual: args as String),
        );
    }
    return null;
  }

  static MaterialPageRoute<void> _pagina(RouteSettings s, Widget tela) =>
      MaterialPageRoute<void>(settings: s, builder: (_) => tela);
}
