import 'package:flutter/widgets.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';

import 'visualizador_io.dart'
    if (dart.library.js_interop) 'visualizador_web.dart'
    as plataforma;

/// Página three.js (assets/navi_3d) rodando dentro do app:
/// - Android/iOS: WebView, com os arquivos servidos pelo [ServidorNavi];
/// - web: iframe, com os arquivos passados como URL na própria página.
abstract class Visualizador {
  /// [aoReceber] recebe as mensagens do JS (progresso, pronto, retrato...).
  factory Visualizador(void Function(Map<String, dynamic>) aoReceber) =
      plataforma.VisualizadorPlataforma;

  static bool get suportado => plataforma.suportado;

  /// Carrega (ou recarrega) a página com o modelo e as animações atuais.
  Future<void> abrir(ArquivosNavi arquivos, Map<String, String> parametros);

  /// Chama `window.navi.<nome>(arg)` na página.
  void comando(String nome, [Object? arg]);

  Widget construir();

  void descartar();
}
