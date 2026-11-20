import 'dart:convert';

import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart' show FalhaApi;
import 'package:codice_app/services/api_navicity.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _endereco = 'http://100.98.182.120:8080';
final _agora = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true);

const _situacao = {
  'id': 42,
  'apelido': 'Karo',
  'area': 'Praça dos Bipes',
  'estado': 'ocioso',
  'areas': ['Praça dos Bipes', 'Biblioteca Velha', 'Café da Esquina'],
};

/// Refaz o que o servidor faz: monta o texto assinado e confere com a chave
/// pública que veio no registro. Se isto passa, o servidor em Go aceita.
Future<bool> _assinaturaConfere(http.BaseRequest r, List<int> chavePublica) async {
  final corpo = r is http.Request ? r.bodyBytes : <int>[];
  final hash = await Sha256().hash(corpo);
  final hex = [for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0')].join();
  final destino = r.url.hasQuery ? '${r.url.path}?${r.url.query}' : r.url.path;
  final texto = '${r.method}\n$destino\n${r.headers['X-Carimbo']}\n$hex';
  return Ed25519().verify(
    utf8.encode(texto),
    signature: Signature(
      base64Decode(r.headers['X-Assinatura']!),
      publicKey: SimplePublicKey(chavePublica, type: KeyPairType.ed25519),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ApiNavicity criar(MockClientHandler responder) => ApiNavicity(
    _endereco,
    cliente: MockClient(responder),
    agora: () => _agora,
  );

  test('recusa HTTP fora de localhost e do Tailscale', () async {
    final api = ApiNavicity('http://192.168.0.10:8080');
    await expectLater(api.situacao(), throwsA(isA<FalhaApi>()));
  });

  test('registro assina o corpo e manda o perfil do app', () async {
    late List<int> chave;
    final api = criar((pedido) async {
      expect(pedido.url.path, '/navis');
      final corpo = jsonDecode(pedido.body) as Map<String, dynamic>;
      chave = base64Decode(corpo['chave_publica'] as String);
      expect(chave, hasLength(32));
      expect(corpo['perfil'], {
        'elemento': 'gelo',
        'tracos': ['curiosa', 'carinhosa'],
      });
      expect(pedido.headers['X-Carimbo'], '1800000000');
      expect(await _assinaturaConfere(pedido, chave), isTrue);
      return http.Response(jsonEncode(_situacao), 201);
    });

    final s = await api.entrar(PerfilNavi.padrao);
    expect(s.id, 42);
    expect(s.apelido, 'Karo');
  });

  test('a mesma identidade é reaproveitada e a consulta leva X-Navi', () async {
    List<int>? primeira;
    final api = criar((pedido) async {
      if (pedido.method == 'POST') {
        primeira = base64Decode(
          (jsonDecode(pedido.body) as Map)['chave_publica'] as String,
        );
        return http.Response(jsonEncode(_situacao), 201);
      }
      expect(pedido.headers['X-Navi'], '42');
      expect(await _assinaturaConfere(pedido, primeira!), isTrue);
      expect(pedido.url.query, 'desde=7');
      return http.Response(
        jsonEncode({
          'cursor': 9,
          'fatos': [
            {
              'seq': 8,
              'quando_s': 120,
              'tipo': 'conheceu',
              'importancia': 'marcante',
              'area': 'Café da Esquina',
              'outro': 'Zeta',
              'lado': 'origem',
              'afinidade': 61,
              'tom': 'indiferente',
            },
          ],
        }),
        200,
      );
    });

    await api.entrar(PerfilNavi.padrao);
    final r = await api.fatos(desde: 7);
    expect(r.cursor, 9);
    expect(r.fatos.single.outro, 'Zeta');
    expect(r.fatos.single.afinidade, 61);
    expect(r.fatos.single.delta, isNull);
  });

  test('registro repetido (409) cai na consulta da situação', () async {
    var chamadas = 0;
    final api = criar((pedido) async {
      chamadas++;
      if (pedido.method == 'POST') {
        return http.Response(jsonEncode({'erro': 'esta chave já tem um NAVI'}), 409);
      }
      return http.Response(jsonEncode(_situacao), 200);
    });
    // Sem id guardado, a consulta falha com mensagem clara, não com erro cru.
    await expectLater(api.entrar(PerfilNavi.padrao), throwsA(isA<FalhaApi>()));
    expect(chamadas, 1);
  });

  test('401 vira mensagem sobre o relógio do celular', () async {
    final api = criar((pedido) async {
      if (pedido.method == 'POST') {
        return http.Response(jsonEncode(_situacao), 201);
      }
      return http.Response(jsonEncode({'erro': 'assinatura inválida'}), 401);
    });
    await api.entrar(PerfilNavi.padrao);
    await expectLater(
      api.situacao(),
      throwsA(
        isA<FalhaApi>().having((e) => e.mensagem, 'mensagem', contains('relógio')),
      ),
    );
  });
}
