import 'dart:convert';

import 'package:codice_app/services/api_codice.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _endereco = 'https://api.codice.test';
const _jwt = 'aaa.bbb.ccc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ApiCodice criar(MockClientHandler responder) =>
      ApiCodice(_endereco, cliente: MockClient(responder));

  test('recusa endereço sem HTTPS', () async {
    final api = ApiCodice('http://api.codice.test');
    await expectLater(api.lerToken(), throwsA(isA<FalhaApi>()));
  });

  test('login guarda o JWT e a consulta envia Bearer', () async {
    final api = criar((pedido) async {
      if (pedido.url.path == '/auth/login') {
        expect(jsonDecode(pedido.body), {'usuario': 'aluno', 'senha': 's'});
        return http.Response(jsonEncode({'access_token': _jwt}), 200);
      }
      expect(pedido.headers['Authorization'], 'Bearer $_jwt');
      return http.Response(
        jsonEncode([
          {'id': 1, 'nome': 'Frost', 'descricao': 'Companheira do diário'},
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await api.entrar('aluno', 's');
    expect(await api.lerToken(), _jwt);
    final navis = await api.consultar();
    expect(navis.single.nome, 'Frost');
    expect(navis.single.descricao, 'Companheira do diário');
  });

  test('401 na consulta vira SessaoExpirada', () async {
    FlutterSecureStorage.setMockInitialValues({'codice.jwt.$_endereco': _jwt});
    final api = criar((_) async => http.Response('{}', 401));
    await expectLater(api.consultar(), throwsA(isA<SessaoExpirada>()));
  });

  test('senha errada e JSON quebrado viram mensagens claras', () async {
    final errada = criar((_) async => http.Response('{}', 401));
    await expectLater(
      errada.entrar('aluno', 'x'),
      throwsA(
        isA<FalhaApi>().having((f) => f.mensagem, 'mensagem', contains('senha')),
      ),
    );
    final quebrada = criar((_) async => http.Response('{', 200));
    await expectLater(
      quebrada.entrar('aluno', 'x'),
      throwsA(
        isA<FalhaApi>().having((f) => f.mensagem, 'mensagem', contains('JSON')),
      ),
    );
  });

  test('HTTP só vale para localhost', () async {
    final local = ApiCodice(
      'http://localhost:8080',
      cliente: MockClient((_) async => throw http.ClientException('x')),
    );
    await expectLater(
      local.entrar('ana', 'senha-boa-123'),
      throwsA(
        isA<FalhaApi>().having(
          (f) => f.mensagem,
          'mensagem',
          contains('node api/servidor.mjs'),
        ),
      ),
    );
    await expectLater(
      ApiCodice('http://192.168.0.10:8080').lerToken(),
      throwsA(isA<FalhaApi>()),
    );
  });

  test('registro guarda o token e mostra o motivo da recusa', () async {
    final api = criar((pedido) async {
      expect(pedido.url.path, '/auth/registro');
      final corpo = jsonDecode(pedido.body) as Map;
      if (corpo['usuario'] == 'ana') {
        return http.Response(
          jsonEncode({'erro': 'Esse usuário já existe.'}),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(jsonEncode({'access_token': _jwt}), 201);
    });

    await api.registrar('bia', 'senha-boa-123');
    expect(await api.lerToken(), _jwt);
    await expectLater(
      api.registrar('ana', 'senha-boa-123'),
      throwsA(
        isA<FalhaApi>().having((f) => f.mensagem, 'mensagem', 'Esse usuário já existe.'),
      ),
    );
  });

  test('servidor fora do ar', () async {
    final api = criar((_) async => throw http.ClientException('recusado'));
    await expectLater(
      api.entrar('aluno', 'x'),
      throwsA(
        isA<FalhaApi>().having(
          (f) => f.mensagem,
          'mensagem',
          contains('indisponível'),
        ),
      ),
    );
  });
}
