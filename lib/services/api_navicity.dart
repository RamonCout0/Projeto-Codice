import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart' show FalhaApi;

/// Endereço do servidor da NAVICity (veja servidor/README.md). Na rede
/// privada (Tailscale) ele é HTTP, porque nenhum segredo trafega: cada pedido
/// é assinado e a chave privada nunca sai do aparelho.
///   flutter run --dart-define=NAVICITY_URL=http://100.x.y.z:8080
const enderecoNavicity = String.fromEnvironment(
  'NAVICITY_URL',
  defaultValue: 'http://localhost:8080',
);

/// HTTP puro só para o próprio aparelho e para a rede do Tailscale
/// (100.64.0.0/10). Qualquer outro endereço precisa ser HTTPS.
bool _redePrivada(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') return true;
  final partes = host.split('.');
  if (partes.length != 4) return false;
  final n = partes.map(int.tryParse).toList();
  if (n.any((v) => v == null || v < 0 || v > 255)) return false;
  return n[0] == 100 && n[1]! >= 64 && n[1]! <= 127;
}

/// Onde o NAVI está na cidade.
class SituacaoNaCidade {
  const SituacaoNaCidade({
    required this.id,
    required this.apelido,
    required this.area,
    required this.estado,
    required this.areas,
  });

  factory SituacaoNaCidade.fromJson(Object? dados) {
    if (dados case {
      'id': int id,
      'apelido': String apelido,
      'area': String area,
      'estado': String estado,
      'areas': List<dynamic> areas,
    }) {
      return SituacaoNaCidade(
        id: id,
        apelido: apelido,
        area: area,
        estado: estado,
        areas: [for (final a in areas) a.toString()],
      );
    }
    throw const FormatException();
  }

  final int id;
  final String apelido;
  final String area;
  final String estado; // ocioso, andando ou conversando
  final List<String> areas;
}

/// Um acontecimento da cidade, do ponto de vista do NAVI do usuário.
class FatoDaCidade {
  const FatoDaCidade({
    required this.seq,
    required this.quandoSegundos,
    required this.tipo,
    required this.importancia,
    required this.area,
    this.destino,
    this.outro,
    this.lado,
    this.afinidade,
    this.delta,
    this.tom,
  });

  factory FatoDaCidade.fromJson(Object? dados) {
    if (dados is Map &&
        dados['seq'] is int &&
        dados['quando_s'] is int &&
        dados['tipo'] is String &&
        dados['importancia'] is String &&
        dados['area'] is String) {
      return FatoDaCidade(
        seq: dados['seq'] as int,
        quandoSegundos: dados['quando_s'] as int,
        tipo: dados['tipo'] as String,
        importancia: dados['importancia'] as String,
        area: dados['area'] as String,
        destino: dados['destino'] as String?,
        outro: dados['outro'] as String?,
        lado: dados['lado'] as String?,
        afinidade: dados['afinidade'] as int?,
        delta: dados['delta'] as int?,
        tom: dados['tom'] as String?,
      );
    }
    throw const FormatException();
  }

  final int seq;
  final int quandoSegundos; // desde o nascimento da cidade
  final String tipo; // entrou, partiu, chegou, conheceu, conversou, recusou, mudou_tom
  final String importancia; // trivial, normal ou marcante
  final String area;
  final String? destino;
  final String? outro; // apelido do outro NAVI
  final String? lado; // "origem" (puxou) ou "alvo" (foi chamado)
  final int? afinidade; // sempre do ponto de vista do NAVI do usuário
  final int? delta;
  final String? tom;
}

class FatosDaCidade {
  const FatosDaCidade(this.fatos, this.cursor);
  final List<FatoDaCidade> fatos;

  /// Mande de volta como `desde` na próxima consulta.
  final int cursor;
}

/// Cliente da NAVICity. A identidade é um par Ed25519 gerado na primeira
/// vez e guardado no armazenamento seguro; o servidor só conhece a chave
/// pública e o id que ele mesmo sorteou.
class ApiNavicity {
  ApiNavicity(
    this.endereco, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    http.Client? cliente,
    DateTime Function()? agora,
  }) : _storage = storage,
       _cliente = cliente,
       _agora = agora ?? DateTime.now;

  final String endereco;
  final FlutterSecureStorage _storage;
  final http.Client? _cliente;
  final DateTime Function() _agora;
  final Ed25519 _algoritmo = Ed25519();

  Uri get _base {
    final uri = Uri.tryParse(endereco);
    final seguro =
        uri != null &&
        (uri.scheme == 'https' ||
            (uri.scheme == 'http' && _redePrivada(uri.host)));
    if (uri == null ||
        !seguro ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FalhaApi(
        'Configure NAVICITY_URL com HTTPS, ou HTTP na rede do Tailscale.',
      );
    }
    return uri;
  }

  String get _chaveSemente => 'navicity.semente.${_base.origin}';
  String get _chaveId => 'navicity.id.${_base.origin}';

  Future<SimpleKeyPair> _par() async {
    try {
      final guardada = await _storage.read(key: _chaveSemente);
      if (guardada != null) {
        return _algoritmo.newKeyPairFromSeed(base64Decode(guardada));
      }
      final novo = await _algoritmo.newKeyPair();
      final semente = await novo.extractPrivateKeyBytes();
      await _storage.write(key: _chaveSemente, value: base64Encode(semente));
      return novo;
    } catch (_) {
      throw const FalhaApi(
        'Não foi possível acessar a identidade no armazenamento seguro.',
      );
    }
  }

  Future<int?> _lerId() async {
    final v = await _storage.read(key: _chaveId);
    return v == null ? null : int.tryParse(v);
  }

  /// Entra na cidade com o perfil do NAVI. Se este aparelho já tem NAVI
  /// registrado, só consulta a situação (o servidor responde 409 a um
  /// registro repetido da mesma chave).
  Future<SituacaoNaCidade> entrar(PerfilNavi perfil) async {
    final par = await _par();
    final publica = await par.extractPublicKey();
    final corpo = jsonEncode({
      'chave_publica': base64Encode(publica.bytes),
      'perfil': {
        'elemento': perfil.elemento.name,
        'tracos': [for (final t in perfil.tracos) t.name],
      },
    });
    final resposta = await _enviar('POST', '/navis', par, corpo: corpo);
    if (resposta.status == 409) return situacao();
    final dados = _interpretar(resposta);
    final situacaoNova = SituacaoNaCidade.fromJson(dados);
    await _storage.write(key: _chaveId, value: '${situacaoNova.id}');
    return situacaoNova;
  }

  Future<SituacaoNaCidade> situacao() async {
    final dados = await _autenticado('GET', '/cidade');
    return SituacaoNaCidade.fromJson(dados);
  }

  /// Fatos novos do NAVI, a partir do cursor da consulta anterior.
  Future<FatosDaCidade> fatos({int desde = 0}) async {
    final dados = await _autenticado('GET', '/fatos?desde=$desde');
    try {
      if (dados case {'fatos': List<dynamic> lista, 'cursor': int cursor}) {
        return FatosDaCidade([
          for (final f in lista) FatoDaCidade.fromJson(f),
        ], cursor);
      }
    } on FormatException {
      // cai no erro abaixo
    }
    throw const FalhaApi('O servidor da NAVICity respondeu algo inesperado.');
  }

  Future<Object?> _autenticado(String metodo, String destino) async {
    final id = await _lerId();
    if (id == null) {
      throw const FalhaApi('Este aparelho ainda não entrou na NAVICity.');
    }
    final resposta = await _enviar(metodo, destino, await _par(), id: id);
    return _interpretar(resposta);
  }

  /// Texto que o servidor confere (veja servidor/README.md):
  /// método, caminho com query, carimbo e sha256 do corpo, um por linha.
  Future<String> _assinar(
    SimpleKeyPair par,
    String metodo,
    String destino,
    int carimbo,
    List<int> corpo,
  ) async {
    final hash = await Sha256().hash(corpo);
    final hex = [for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0')].join();
    final mensagem = utf8.encode('$metodo\n$destino\n$carimbo\n$hex');
    final assinatura = await _algoritmo.sign(mensagem, keyPair: par);
    return base64Encode(assinatura.bytes);
  }

  Future<({int status, String corpo})> _enviar(
    String metodo,
    String destino,
    SimpleKeyPair par, {
    String corpo = '',
    int? id,
  }) async {
    final carimbo = _agora().millisecondsSinceEpoch ~/ 1000;
    final bytes = utf8.encode(corpo);
    final pedido = http.Request(metodo, _base.resolve(destino))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json'
      ..headers['X-Carimbo'] = '$carimbo'
      ..headers['X-Assinatura'] = await _assinar(
        par,
        metodo,
        destino,
        carimbo,
        bytes,
      );
    if (id != null) pedido.headers['X-Navi'] = '$id';
    if (corpo.isNotEmpty) {
      pedido.headers['Content-Type'] = 'application/json';
      pedido.bodyBytes = bytes;
    }

    final cliente = _cliente ?? http.Client();
    try {
      final r = await http.Response.fromStream(
        await cliente.send(pedido),
      ).timeout(const Duration(seconds: 8));
      return (status: r.statusCode, corpo: utf8.decode(r.bodyBytes));
    } on TimeoutException {
      throw const FalhaApi('A NAVICity demorou para responder.');
    } on http.ClientException {
      throw const FalhaApi('Não consegui falar com a NAVICity.');
    } finally {
      if (_cliente == null) cliente.close();
    }
  }

  Object? _interpretar(({int status, String corpo}) r) {
    if (r.status == 401) {
      throw const FalhaApi(
        'A NAVICity não reconheceu este aparelho. Confira o relógio do '
        'celular ou entre de novo na cidade.',
      );
    }
    if (r.status == 400 || r.status == 409) {
      try {
        final d = jsonDecode(r.corpo);
        if (d is Map && d['erro'] is String) throw FalhaApi(d['erro'] as String);
      } on FormatException {
        // sem mensagem útil: cai no erro genérico
      }
    }
    if (r.status >= 500) {
      throw const FalhaApi('A NAVICity está indisponível. Tente mais tarde.');
    }
    if (r.status != 200 && r.status != 201) {
      throw FalhaApi('A NAVICity respondeu com erro ${r.status}.');
    }
    try {
      return jsonDecode(r.corpo);
    } on FormatException {
      throw const FalhaApi('A NAVICity respondeu um JSON inválido.');
    }
  }
}
