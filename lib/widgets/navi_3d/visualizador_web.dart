import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'visualizador.dart';

bool get suportado => true;

/// Na web o visualizador é um iframe da mesma origem do app. Os arquivos
/// chegam como URL: do próprio app (assets/navi_local) ou blob: (importados
/// nesta aba). As mensagens vão e voltam por postMessage.
class VisualizadorPlataforma implements Visualizador {
  VisualizadorPlataforma(this._aoReceber) {
    ui_web.platformViewRegistry.registerViewFactory(
      _tipo,
      (_) => _iframe,
    );
    _ouvinte = ((web.MessageEvent e) {
      if (e.origin != web.window.location.origin) return;
      final dados = e.data;
      if (dados == null || !dados.isA<JSString>()) return;
      final Object? mensagem;
      try {
        mensagem = jsonDecode((dados as JSString).toDart);
      } on FormatException {
        return;
      }
      // Cada iframe responde com o próprio canal (vai na URL dele).
      if (mensagem is Map<String, dynamic> && mensagem['canal'] == _tipo) {
        _aoReceber(mensagem);
      }
    }).toJS;
    web.window.addEventListener('message', _ouvinte);
  }

  static int _contador = 0;
  final _tipo = 'navi-3d-${_contador++}';
  final void Function(Map<String, dynamic>) _aoReceber;
  late final JSFunction _ouvinte;
  final _blobs = <String>[];
  bool _aberto = false;

  late final web.HTMLIFrameElement _iframe = web.HTMLIFrameElement()
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'transparent'
    ..setAttribute('allowtransparency', 'true');

  static String _absoluta(String chaveAsset) => Uri.base
      .resolve(ui_web.assetManager.getAssetUrl(chaveAsset))
      .toString();

  String _url(FonteNavi fonte) => switch (fonte) {
    FonteAsset(:final chave) => _absoluta(chave),
    FonteBytes(:final bytes) => _blob(bytes),
    FonteArquivo() => throw UnsupportedError('arquivo local na web'),
  };

  String _blob(List<int> bytes) {
    final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    _blobs.add(url);
    return url;
  }

  void _liberarBlobs() {
    for (final url in _blobs) {
      web.URL.revokeObjectURL(url);
    }
    _blobs.clear();
  }

  @override
  Future<void> abrir(
    ArquivosNavi arquivos,
    Map<String, String> parametros,
  ) async {
    final modelo = arquivos.modelo;
    if (modelo == null) return;
    _liberarBlobs();
    final animacoes = {
      for (final MapEntry(key: g, value: f) in arquivos.animacoes.entries)
        g.name: {'url': _url(f), 'formato': f.extensao},
    };
    final pagina = Uri.parse(_absoluta('assets/navi_3d/index.html')).replace(
      queryParameters: {
        ...parametros,
        'canal': _tipo,
        'modelo': _url(modelo),
        'animacoes': jsonEncode(animacoes),
      },
    );
    _iframe.src = pagina.toString();
    _aberto = true;
  }

  @override
  void comando(String nome, [Object? arg]) {
    _iframe.contentWindow?.postMessage(
      jsonEncode({'naviComando': nome, 'arg': arg}).toJS,
      web.window.location.origin.toJS,
    );
  }

  @override
  Widget construir() =>
      _aberto ? HtmlElementView(viewType: _tipo) : const SizedBox.shrink();

  @override
  void descartar() {
    web.window.removeEventListener('message', _ouvinte);
    _liberarBlobs();
  }
}
