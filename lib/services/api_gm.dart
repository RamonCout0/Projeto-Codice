import 'dart:async';
import 'dart:convert';

import 'package:codice_app/services/cofre.dart';
import 'package:http/http.dart' as http;
import 'package:codice_app/services/api_codice.dart' show FalhaApi, hostDeRedePrivada;
import 'package:codice_app/services/api_navicity.dart' show enderecoNavicity;

/// O que o dono da cidade configura na Iris: os cinco traços (0 a 100) que
/// movem o comportamento dela e um texto de personalidade.
class ConfigIris {
  static const chaves = ['coragem', 'curiosidade', 'paciencia', 'sociabilidade', 'agressividade'];
  static const maxPersonalidade = 800;

  final Map<String, int> tracos;
  final String personalidade;

  const ConfigIris({required this.tracos, required this.personalidade});

  factory ConfigIris.fromJson(Object? dados) {
    if (dados is Map && dados['tracos'] is Map && dados['personalidade'] is String) {
      final t = dados['tracos'] as Map;
      if (chaves.every((c) => t[c] is int)) {
        return ConfigIris(
          tracos: {for (final c in chaves) c: t[c] as int},
          personalidade: dados['personalidade'] as String,
        );
      }
    }
    throw const FormatException();
  }

  Map<String, Object> toJson() => {'tracos': tracos, 'personalidade': personalidade};

  ConfigIris copiar({Map<String, int>? tracos, String? personalidade}) =>
      ConfigIris(tracos: tracos ?? this.tracos, personalidade: personalidade ?? this.personalidade);
}

/// Rotas de administração da NAVICity (/gm/iris). Exigem a chave de
/// administrador do servidor, que fica só no armazenamento seguro daqui.
class ApiGm {
  ApiGm({
    String? endereco,
    Cofre storage = const Cofre(),
    http.Client? cliente,
  }) : endereco = endereco ?? enderecoNavicity,
       _storage = storage,
       _cliente = cliente;

  static const _chaveArmazenada = 'navicity.admin';

  final String endereco;
  final Cofre _storage;
  final http.Client? _cliente;

  Uri get _base {
    final uri = Uri.tryParse(endereco);
    final seguro = uri != null &&
        (uri.scheme == 'https' || (uri.scheme == 'http' && hostDeRedePrivada(uri.host)));
    if (uri == null || !seguro || uri.host.isEmpty) {
      throw const FalhaApi('Configure NAVICITY_URL com HTTPS, ou HTTP na rede do Tailscale.');
    }
    return uri;
  }

  Future<String?> chaveGuardada() async {
    try {
      return await _storage.read(key: _chaveArmazenada);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarChave(String chave) async {
    try {
      await _storage.write(key: _chaveArmazenada, value: chave);
    } catch (_) {
      throw const FalhaApi('Não consegui guardar a chave no armazenamento seguro.');
    }
  }

  Future<void> esquecerChave() async {
    try {
      await _storage.delete(key: _chaveArmazenada);
    } catch (_) {}
  }

  Future<ConfigIris> ler(String chave) async => _config(await _enviar('GET', chave));

  Future<ConfigIris> salvar(String chave, ConfigIris config) async =>
      _config(await _enviar('PUT', chave, corpo: config.toJson()));

  ConfigIris _config(Object? dados) {
    try {
      return ConfigIris.fromJson(dados);
    } on FormatException {
      throw const FalhaApi('O servidor respondeu algo inesperado.');
    }
  }

  Future<Object?> _enviar(String metodo, String chave, {Map<String, Object>? corpo}) async {
    final pedido = http.Request(metodo, _base.replace(path: '/gm/iris'))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${chave.trim()}';
    if (corpo != null) {
      pedido.headers['Content-Type'] = 'application/json';
      pedido.body = jsonEncode(corpo);
    }
    final cliente = _cliente ?? http.Client();
    try {
      final r = await http.Response.fromStream(await cliente.send(pedido))
          .timeout(const Duration(seconds: 8));
      final texto = utf8.decode(r.bodyBytes);
      switch (r.statusCode) {
        case 200:
          return jsonDecode(texto);
        case 401:
          throw const FalhaApi('Chave de administrador inválida.');
        case 404:
          throw const FalhaApi('A configuração da Iris está desligada neste servidor.');
        case 400:
          try {
            final d = jsonDecode(texto);
            if (d is Map && d['erro'] is String) throw FalhaApi(d['erro'] as String);
          } on FormatException {
            // sem mensagem útil
          }
          throw const FalhaApi('O servidor recusou a configuração.');
        default:
          throw FalhaApi('O servidor respondeu com erro ${r.statusCode}.');
      }
    } on TimeoutException {
      throw const FalhaApi('O servidor demorou para responder.');
    } on http.ClientException {
      throw const FalhaApi('Não consegui falar com a NAVICity.');
    } on FormatException {
      throw const FalhaApi('O servidor respondeu algo inesperado.');
    } finally {
      if (_cliente == null) cliente.close();
    }
  }
}
