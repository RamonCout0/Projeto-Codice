import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/services/navi_3d/servidor_navi.dart';
import 'visualizador.dart';

bool get suportado => Platform.isAndroid || Platform.isIOS;

class VisualizadorPlataforma implements Visualizador {
  VisualizadorPlataforma(this._aoReceber);

  final void Function(Map<String, dynamic>) _aoReceber;
  WebViewController? _controle;

  @override
  Future<void> abrir(
    ArquivosNavi arquivos,
    Map<String, String> parametros,
  ) async {
    final base = await ServidorNavi.endereco(arquivos);
    final controle = _controle ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Navi',
        onMessageReceived: (m) =>
            _aoReceber(jsonDecode(m.message) as Map<String, dynamic>),
      );
    await controle.loadRequest(base.replace(queryParameters: parametros));
  }

  @override
  void comando(String nome, [Object? arg]) => _controle?.runJavaScript(
    'window.navi?.$nome(${arg == null ? '' : jsonEncode(arg)})',
  );

  @override
  Widget construir() {
    final controle = _controle;
    return controle == null
        ? const SizedBox.shrink()
        : WebViewWidget(controller: controle);
  }

  @override
  void descartar() {}
}
