import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';

/// Servidor HTTP só dentro do aparelho (127.0.0.1) que entrega o
/// visualizador 3D para a WebView. Abrir os arquivos direto com file://
/// não funciona: a WebView bloqueia o carregamento do modelo.
/// (Na web o visualizador roda num iframe e não precisa deste servidor.)
class ServidorNavi {
  ServidorNavi._();

  static Future<Uri>? _endereco;

  static Future<Uri> endereco(ArquivosNavi arquivos) =>
      _endereco ??= _iniciar(arquivos);

  static Future<Uri> _iniciar(ArquivosNavi arquivos) async {
    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((pedido) => _responder(pedido, arquivos));
    return Uri.parse('http://127.0.0.1:${servidor.port}');
  }

  static Future<void> _responder(
    HttpRequest pedido,
    ArquivosNavi arquivos,
  ) async {
    final resposta = pedido.response;
    final caminho = pedido.uri.path;
    try {
      if (caminho == '/' || caminho == '/index.html') {
        await _asset(
          resposta,
          'assets/navi_3d/index.html',
          'text/html; charset=utf-8',
        );
      } else if (caminho == '/navi.js') {
        await _asset(
          resposta,
          'assets/navi_3d/navi.js',
          'text/javascript; charset=utf-8',
        );
      } else if (caminho == '/modelo.vrm' && arquivos.modelo != null) {
        await _fonte(resposta, arquivos.modelo!);
      } else if (caminho == '/animacoes.json') {
        // A extensão diz ao visualizador como ler: .vrma ou .fbx (Mixamo).
        final lista = {
          for (final MapEntry(key: g, value: f) in arquivos.animacoes.entries)
            g.name: '/anim/${g.name}.${f.extensao}',
        };
        resposta.headers.contentType = ContentType.json;
        resposta.write(jsonEncode(lista));
      } else if (caminho.startsWith('/anim/')) {
        final nome = caminho.substring(6).split('.').first;
        final gesto = Gesto.values.where((g) => g.name == nome).firstOrNull;
        final fonte = gesto == null ? null : arquivos.animacoes[gesto];
        if (fonte == null) {
          resposta.statusCode = HttpStatus.notFound;
        } else {
          await _fonte(resposta, fonte);
        }
      } else {
        resposta.statusCode = HttpStatus.notFound;
      }
    } catch (_) {
      resposta.statusCode = HttpStatus.internalServerError;
    }
    await resposta.close();
  }

  static Future<void> _asset(HttpResponse r, String asset, String tipo) async {
    final dados = await rootBundle.load(asset);
    r.headers.set(HttpHeaders.contentTypeHeader, tipo);
    r.add(dados.buffer.asUint8List(dados.offsetInBytes, dados.lengthInBytes));
  }

  static Future<void> _fonte(HttpResponse r, FonteNavi fonte) async {
    r.headers.contentType = ContentType.binary;
    switch (fonte) {
      case FonteArquivo(:final arquivo):
        r.headers.contentLength = await arquivo.length();
        await r.addStream(arquivo.openRead());
      case FonteBytes(:final bytes):
        r.add(bytes);
      case FonteAsset(:final chave):
        final dados = await rootBundle.load(chave);
        r.add(dados.buffer.asUint8List(dados.offsetInBytes, dados.lengthInBytes));
    }
  }
}
