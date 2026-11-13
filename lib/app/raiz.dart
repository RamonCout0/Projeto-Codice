import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/codice_app.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';

/// Estado global do app, disponível em todas as telas pelo Provider.
class RaizCodice extends StatelessWidget {
  const RaizCodice({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EstadoCodice()),
        ChangeNotifierProvider(create: (_) => Ajustes()..carregar()),
        ChangeNotifierProvider(create: (_) => ArquivosNavi()..carregar()),
      ],
      child: const CodiceApp(),
    );
  }
}
