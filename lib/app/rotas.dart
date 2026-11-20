import 'package:flutter/material.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/views/app_shell.dart';
import 'package:codice_app/views/boas_vindas_tela.dart';
import 'package:codice_app/views/cidade/cidade_tela.dart';
import 'package:codice_app/views/cidade/lugar_tela.dart';
import 'package:codice_app/views/configuracoes_tela.dart';
import 'package:codice_app/views/conversa/conversa_tela.dart';
import 'package:codice_app/views/diario/diario_tela.dart';
import 'package:codice_app/views/encontros/apelido_tela.dart';
import 'package:codice_app/views/encontros/detalhe_navi_tela.dart';
import 'package:codice_app/views/encontros/encontros_tela.dart';
import 'package:codice_app/views/home/home_tela.dart';
import 'package:codice_app/views/importar_navi_tela.dart';
import 'package:codice_app/views/iris_config_tela.dart';
import 'package:codice_app/views/perfil_navi_tela.dart';
import 'package:codice_app/views/sessao_segura_tela.dart';

abstract final class Rotas {
  // Pilha raiz.
  static const inicio = '/';
  static const app = '/app';
  static const configuracoes = '/configuracoes';
  static const importar = '/importar';
  static const sessao = '/sessao';
  static const perfil = '/perfil';
  static const iris = '/iris';

  // Raízes das abas e telas empilhadas dentro delas.
  static const navi = '/navi';
  static const conversa = '/conversa';
  static const diario = '/diario';
  static const cidade = '/cidade';
  static const lugar = '/cidade/lugar';
  static const encontros = '/encontros';
  static const naviEncontrado = '/encontros/navi';
  static const apelido = '/encontros/apelido';

  static final Map<String, WidgetBuilder> mapa = {
    inicio: (_) => const BoasVindasTela(),
    app: (_) => const AppShell(),
    configuracoes: (_) => const ConfiguracoesTela(),
    importar: (_) => const ImportarNaviTela(),
    iris: (_) => const IrisConfigTela(),
    // arguments: true = logo depois de criar a conta (segue para o app).
    perfil: (c) => PerfilNaviTela(
      criando: ModalRoute.of(c)?.settings.arguments == true,
    ),
    // arguments: true abre no modo "criar conta".
    sessao: (c) => SessaoSeguraTela(
      criarConta: ModalRoute.of(c)?.settings.arguments == true,
    ),
  };

  /// Usado pelo MaterialApp e pelo Navigator de cada aba: é aqui que os
  /// arguments viram parâmetros das telas.
  static Route<dynamic>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? tela = switch (settings.name) {
      navi => const HomeTela(),
      conversa => const ConversaTela(),
      diario => const DiarioTela(),
      cidade => const CidadeTela(),
      lugar => LugarTela(lugar: args as Lugar),
      encontros => const EncontrosTela(),
      naviEncontrado => DetalheNaviTela(navi: args as NaviEncontrado),
      _ => null,
    };
    if (tela != null) {
      return MaterialPageRoute<void>(settings: settings, builder: (_) => tela);
    }
    // Tipada como <String>: quem chama recebe o apelido de volta no pop.
    if (settings.name == apelido) {
      return MaterialPageRoute<String>(
        settings: settings,
        builder: (_) => ApelidoTela(apelidoAtual: args as String),
      );
    }
    return null;
  }
}
