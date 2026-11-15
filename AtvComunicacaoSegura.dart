import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FalhaApi implements Exception {
  const FalhaApi(this.mensagem);
  final String mensagem;
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

class ApiCodice {
  ApiCodice(
    this.endereco, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final String endereco;
  final FlutterSecureStorage _storage;

  Uri get _base {
    final uri = Uri.tryParse(endereco);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FalhaApi(
        'Configure CODICE_API_URL com o endereço HTTPS da API.',
      );
    }
    return uri;
  }

  String get _chave => 'codice.jwt.${_base.origin}';

  Future<String?> lerToken() async {
    final chave = _chave;
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
    try {
      await _storage.delete(key: chave);
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível apagar a sessão do armazenamento seguro.',
      );
    }
  }

  Future<void> entrar(String usuario, String senha) async {
    final dados = await _requisicao(
      'POST',
      '/auth/login',
      corpo: {'usuario': usuario, 'senha': senha},
    );
    if (dados is! Map ||
        dados['access_token'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$')
            .hasMatch(dados['access_token'] as String)) {
      throw const FalhaApi('A resposta JSON não trouxe um token JWT válido.');
    }
    try {
      await _storage.write(key: _chave, value: dados['access_token'] as String);
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível guardar a sessão no armazenamento seguro.',
      );
    }
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
    Map<String, String>? corpo,
  }) async {
    final uri = _base.replace(path: rota);
    final cliente = HttpClient();
    try {
      return await _enviar(
        cliente,
        metodo,
        uri,
        token,
        corpo,
      ).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const FalhaApi('A API demorou para responder. Tente novamente.');
    } on HandshakeException {
      throw const FalhaApi(
        'Não foi possível verificar a conexão HTTPS da API.',
      );
    } on IOException {
      throw const FalhaApi(
        'Servidor indisponível. Confira a conexão e tente novamente.',
      );
    } on FormatException {
      throw const FalhaApi('A API retornou um JSON inválido.');
    } finally {
      cliente.close(force: true);
    }
  }

  Future<Object?> _enviar(
    HttpClient cliente,
    String metodo,
    Uri uri,
    String? token,
    Map<String, String>? corpo,
  ) async {
    final pedido = await cliente.openUrl(metodo, uri);
    pedido.followRedirects = false;
    pedido.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      pedido.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (corpo != null) {
      pedido.headers.contentType = ContentType.json;
      pedido.add(utf8.encode(jsonEncode(corpo)));
    }
    final resposta = await pedido.close();
    if (resposta.statusCode == 401) {
      if (token != null) throw const SessaoExpirada();
      throw const FalhaApi('Usuário ou senha inválidos.');
    }
    if (resposta.statusCode >= 500) {
      throw const FalhaApi(
        'Servidor indisponível. Tente novamente mais tarde.',
      );
    }
    if (resposta.statusCode != 200) {
      throw FalhaApi('A API respondeu com erro ${resposta.statusCode}.');
    }
    final texto = await utf8.decoder.bind(resposta).join();
    return jsonDecode(texto);
  }
}

class SessaoSeguraScreen extends StatefulWidget {
  const SessaoSeguraScreen({super.key, required this.aoContinuar, this.api});

  final void Function(BuildContext) aoContinuar;
  final ApiCodice? api;

  @override
  State<SessaoSeguraScreen> createState() => _SessaoSeguraScreenState();
}

class _SessaoSeguraScreenState extends State<SessaoSeguraScreen> {
  late final ApiCodice _api =
      widget.api ?? ApiCodice(const String.fromEnvironment('CODICE_API_URL'));
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<NaviDaApi>? _navis;
  String? _aviso;
  String? _erro;
  bool _ocupado = false;
  bool _consultando = false;
  bool _limpezaPendente = false;

  @override
  void initState() {
    super.initState();
    _executar(() async {
      if (await _api.lerToken() == null || !mounted) return;
      _aviso = 'Sessão recuperada do armazenamento seguro.';
      await _consultar();
    });
  }

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao();
    } on SessaoExpirada catch (falha) {
      await _sair(falha.mensagem);
    } on FalhaApi catch (falha) {
      if (mounted) _erro = falha.mensagem;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _sair(String mensagem) async {
    if (!mounted) return;
    _consultando = false;
    _navis = null;
    _aviso = null;
    _limpezaPendente = true;
    _erro = mensagem;
    try {
      await _api.apagarSessao();
      if (mounted) _limpezaPendente = false;
    } on FalhaApi catch (falha) {
      if (mounted) _erro = '$mensagem ${falha.mensagem}';
    }
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final senha = _senha.text;
    _senha.clear();
    await _executar(() async {
      await _api.entrar(_usuario.text.trim(), senha);
      if (!mounted) return;
      _aviso = 'Login realizado. Sessão guardada com segurança.';
      await _consultar();
    });
  }

  Future<void> _consultar() async {
    if (!mounted) return;
    setState(() {
      _consultando = true;
      _navis = null;
    });
    final navis = await _api.consultar();
    if (mounted) _navis = navis;
  }

  String? _obrigatorio(String? valor) =>
      valor == null || valor.trim().isEmpty ? 'Preencha este campo.' : null;

  @override
  Widget build(BuildContext context) {
    final navis = _navis;
    return PopScope(
      canPop: !_ocupado,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_consultando ? 'Consulta de NAVIs' : 'Entrar no Códice'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_aviso != null) Text(_aviso!),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erro!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_ocupado)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: LinearProgressIndicator(),
                )
              else if (_limpezaPendente)
                FilledButton(
                  onPressed: () => _executar(() => _sair('Entre novamente.')),
                  child: const Text('Tentar apagar a sessão'),
                )
              else if (_consultando) ...[
                if (navis != null) ...[
                  if (navis.isEmpty)
                    const ListTile(title: Text('Nenhum NAVI cadastrado.')),
                  for (final navi in navis)
                    ListTile(
                      title: Text(navi.nome),
                      subtitle: Text('ID: ${navi.id}\n${navi.descricao}'),
                    ),
                  FilledButton(
                    onPressed: () => widget.aoContinuar(context),
                    child: const Text('Ir para o Códice'),
                  ),
                ],
                OutlinedButton(
                  onPressed: () => _executar(_consultar),
                  child: Text(
                    navis == null ? 'Tentar novamente' : 'Atualizar lista',
                  ),
                ),
                TextButton(
                  onPressed: () => _executar(() => _sair('Sessão encerrada.')),
                  child: const Text('Sair da sessão'),
                ),
              ] else
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usuario,
                        decoration: const InputDecoration(labelText: 'Usuário'),
                        textInputAction: TextInputAction.next,
                        validator: _obrigatorio,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _senha,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        validator: _obrigatorio,
                        onFieldSubmitted: (_) => _entrar(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _entrar,
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
