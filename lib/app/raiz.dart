import 'package:flutter/material.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/codice_app.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';

/// Estado global do app, disponível em todas as telas pelo Provider.
class RaizCodice extends StatelessWidget {
  /// Os testes passam uma cidade com servidor simulado.
  final CidadeNavi? cidade;

  const RaizCodice({super.key, this.cidade});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EstadoCodice()..carregar()),
        ChangeNotifierProvider(create: (_) => cidade ?? CidadeNavi()),
        ChangeNotifierProvider(create: (_) => NavegacaoAbas()),
        ChangeNotifierProvider(create: (_) => Ajustes()..carregar()),
        ChangeNotifierProvider(create: (_) => ArquivosNavi()..carregar()),
        // Conta e personalidade do NAVI (a sessão guardada é conferida na
        // tela inicial).
        ChangeNotifierProvider(create: (_) => Sessao()),
      ],
      child: const CodiceApp(),
    );
  }
}
