import 'dart:async';
import 'dart:convert';
import 'dart:io' show HandshakeException;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:codice_app/models/perfil_navi.dart';

/// Endereço da API de comunicação segura (veja api/servidor.mjs).
/// Sem nada, usa a API rodando no próprio PC (`node api/servidor.mjs`).
/// Para outro endereço, que precisa ser HTTPS:
///   flutter run --dart-define=CODICE_API_URL=https://SEU-ENDERECO
const enderecoApiCodice = String.fromEnvironment(
  'CODICE_API_URL',
  defaultValue: 'http://localhost:8080',
);

/// HTTP sem TLS só é aceito para o próprio aparelho: o tráfego não sai dele.
/// (No emulador Android, `adb reverse tcp:8080 tcp:8080` liga o localhost
/// do emulador ao do PC.)
bool _ehLocal(String host) =>
    host == 'localhost' || host == '127.0.0.1' || host == '::1';

class FalhaApi implements Exception {
  const FalhaApi(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

class SessaoExpirada extends FalhaApi {
  const SessaoExpirada()
    : super('Sessão inválida ou expirada. Entre novamente.');
}

class NaviDaApi {
  const NaviDaApi(this.id, this.nome, this.descricao);

  factory NaviDaApi.fromJson(Object? dados) {
    if (dados case {
      'id': int id,
      'nome': String nome,
      'descricao': String descricao,
    }) {
      return NaviDaApi(id, nome, descricao);
    }
    throw const FormatException();
  }

  final int id;
  final String nome;
  final String descricao;
}

/// Login JWT e consulta protegida. O token fica no armazenamento seguro do
/// sistema (Keystore no Android); a senha nunca é guardada.
class ApiCodice {
  ApiCodice(
    this.endereco, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    http.Client? cliente,
  }) : _storage = storage,
       _cliente = cliente;

  final String endereco;
  final FlutterSecureStorage _storage;
  final http.Client? _cliente;

  /// Sem "manter conectado", o token vive só aqui, enquanto o app está
  /// aberto, e nunca é gravado no aparelho.
  String? _tokenDaAba;

  static final _formatoJwt = RegExp(
    r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
  );

  /// Só aceita HTTPS (ou HTTP no próprio aparelho): credenciais e token
  /// nunca trafegam em texto puro pela rede.
  Uri get _base {
    final uri = Uri.tryParse(endereco);
    final seguro =
        uri != null &&
        (uri.scheme == 'https' || (uri.scheme == 'http' && _ehLocal(uri.host)));
    if (uri == null ||
        !seguro ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FalhaApi(
        'Configure CODICE_API_URL com o endereço HTTPS da API '
        '(HTTP só para localhost).',
      );
    }
    return uri;
  }

  String get _chave => 'codice.jwt.${_base.origin}';

  Future<String?> lerToken() async {
    final chave = _chave;
    if (_tokenDaAba != null) return _tokenDaAba;
    try {
      return await _storage.read(key: chave);
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível ler a sessão no armazenamento seguro.',
      );
    }
  }

  Future<void> apagarSessao() async {
    final chave = _chave;
    _tokenDaAba = null;
    try {
      await _storage.delete(key: chave);
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível apagar a sessão do armazenamento seguro.',
      );
    }
  }

  /// [manter]: guarda o token no armazenamento seguro, para a sessão
  /// continuar quando o app for reaberto.
  Future<void> entrar(String usuario, String senha, {bool manter = true}) =>
      _autenticar('/auth/login', usuario, senha, manter);

  /// Cria a conta e já entra com ela.
  Future<void> registrar(
    String usuario,
    String senha, {
    bool manter = true,
  }) => _autenticar('/auth/registro', usuario, senha, manter);

  Future<void> _autenticar(
    String rota,
    String usuario,
    String senha,
    bool manter,
  ) async {
    final dados = await _requisicao(
      'POST',
      rota,
      corpo: {'usuario': usuario, 'senha': senha},
    );
    final token = dados is Map ? dados['access_token'] : null;
    if (token is! String || !_formatoJwt.hasMatch(token)) {
      throw const FalhaApi('A resposta JSON não trouxe um token JWT válido.');
    }
    try {
      if (manter) {
        _tokenDaAba = null;
        await _storage.write(key: _chave, value: token);
      } else {
        _tokenDaAba = token;
        await _storage.delete(key: _chave); // não sobra sessão antiga
      }
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível guardar a sessão no armazenamento seguro.',
      );
    }
  }

  /// NAVI da conta, ou null se ela ainda não criou um.
  Future<({String usuario, PerfilNavi? navi})> lerPerfil() async {
    final token = await lerToken();
    if (token == null || token.isEmpty) throw const SessaoExpirada();
    final dados = await _requisicao('GET', '/perfil', token: token, aceitar404: true);
    return _perfilDe(dados);
  }

  Future<({String usuario, PerfilNavi? navi})> salvarPerfil(
    PerfilNavi perfil,
  ) async {
    final token = await lerToken();
    if (token == null || token.isEmpty) throw const SessaoExpirada();
    final dados = await _requisicao(
      'PUT',
      '/perfil',
      token: token,
      corpo: perfil.toJson(),
    );
    return _perfilDe(dados);
  }

  static ({String usuario, PerfilNavi? navi}) _perfilDe(Object? dados) {
    if (dados is Map && dados['usuario'] is String) {
      return (
        usuario: dados['usuario'] as String,
        navi: PerfilNavi.fromJson(dados['navi']),
      );
    }
    throw const FalhaApi('A API retornou um perfil inválido.');
  }

  Future<List<NaviDaApi>> consultar() async {
    final token = await lerToken();
    if (token == null || token.isEmpty) throw const SessaoExpirada();
    final dados = await _requisicao('GET', '/navis', token: token);
    try {
      if (dados is! List) throw const FormatException();
      return dados.map(NaviDaApi.fromJson).toList();
    } on FormatException {
      throw const FalhaApi('A API retornou uma lista de NAVIs inválida.');
    }
  }

  Future<Object?> _requisicao(
    String metodo,
    String rota, {
    String? token,
    Map<String, Object>? corpo,
    bool aceitar404 = false,
  }) async {
    final pedido = http.Request(metodo, _base.replace(path: rota))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (token != null) pedido.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) {
      pedido.headers['Content-Type'] = 'application/json';
      pedido.body = jsonEncode(corpo);
    }

    final cliente = _cliente ?? http.Client();
    try {
      final resposta = await http.Response.fromStream(
        await cliente.send(pedido),
      ).timeout(const Duration(seconds: 8));
      if (aceitar404 && resposta.statusCode == 404) {
        return jsonDecode(utf8.decode(resposta.bodyBytes));
      }
      return _ler(resposta, comToken: token != null);
    } on TimeoutException {
      throw const FalhaApi('A API demorou para responder. Tente novamente.');
    } on HandshakeException {
      throw const FalhaApi(
        'Não foi possível verificar a conexão HTTPS da API.',
      );
    } on http.ClientException {
      throw FalhaApi(
        _ehLocal(_base.host)
            ? 'A API não está rodando. No terminal: node api/servidor.mjs'
            : 'Servidor indisponível. Confira a conexão e tente novamente.',
      );
    } on FormatException {
      throw const FalhaApi('A API retornou um JSON inválido.');
    } finally {
      if (_cliente == null) cliente.close();
    }
  }

  Object? _ler(http.Response resposta, {required bool comToken}) {
    final status = resposta.statusCode;
    if (status == 401) {
      if (comToken) throw const SessaoExpirada();
      throw const FalhaApi('Usuário ou senha inválidos.');
    }
    // Registro recusado: a API explica o motivo (usuário repetido etc.).
    if (status == 400 || status == 409) {
      final erro = _mensagemDaApi(resposta);
      if (erro != null) throw FalhaApi(erro);
    }
    if (status >= 500) {
      throw const FalhaApi('Servidor indisponível. Tente novamente mais tarde.');
    }
    if (status != 200 && status != 201) {
      throw FalhaApi('A API respondeu com erro $status.');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  static String? _mensagemDaApi(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      return dados is Map && dados['erro'] is String
          ? dados['erro'] as String
          : null;
    } on FormatException {
      return null;
    }
  }
}
