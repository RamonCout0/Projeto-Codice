import 'dart:convert';

import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/data/lugares_demo.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart';
import 'package:codice_app/services/conversa_gemma.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jwt = 'aaa.bbb.ccc';
const _faisca = PerfilNavi(
  nome: 'Faísca',
  elemento: Elemento.eletrico,
  tracos: [Traco.brincalhona, Traco.dramatica],
  gostos: 'jogos de tabuleiro',
);

http.Response _json(Object dados, int status) => http.Response(
  jsonEncode(dados),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// API falsa: guarda o perfil enviado e devolve na leitura.
MockClient apiFalsa({PerfilNavi? inicial}) {
  Map<String, Object>? navi = inicial?.toJson();
  return MockClient((pedido) async {
    switch (pedido.url.path) {
      case '/auth/login' || '/auth/registro':
        return _json({'access_token': _jwt}, 200);
      case '/perfil' when pedido.method == 'PUT':
        navi = (jsonDecode(pedido.body) as Map).cast<String, Object>();
        return _json({'usuario': 'ana', 'navi': navi}, 200);
      case '/perfil':
        if (navi == null) {
          return _json({'usuario': 'ana', 'erro': 'sem NAVI'}, 404);
        }
        return _json({'usuario': 'ana', 'navi': navi}, 200);
    }
    return http.Response('{}', 404);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('o prompt do Gemma leva elemento, traços, gostos e memórias', () {
    final prompt = ConversaGemma.instrucoes(_faisca, [
      Memoria('Tenho prova sexta.', {'prova'}, DateTime(2026, 11, 1)),
    ]);
    expect(prompt, contains('Você é Faísca'));
    expect(prompt, contains(Elemento.eletrico.jeito));
    expect(prompt, contains(Traco.brincalhona.jeito));
    expect(prompt, contains(Traco.dramatica.jeito));
    expect(prompt, contains('jogos de tabuleiro'));
    expect(prompt, contains('Tenho prova sexta.'));
  });

  test('o prompt conta a vida do NAVI: lugares e NAVIs que conheceu', () {
    final estado = EstadoCodice();
    final prompt = ConversaGemma.instrucoes(
      _faisca,
      const [],
      lugares: lugares,
      encontros: estado.navis,
    );
    expect(prompt, contains('Biblioteca Velha'));
    expect(prompt, contains('Pixel (72)'));
    expect(prompt, contains('Faísca achou engraçado')); // "Frost" vira o nome
    expect(prompt, isNot(contains('Frost')));
    expect(prompt, contains('Se perguntarem sobre você'));
  });

  test('perfil vai e volta em JSON e recusa valores desconhecidos', () {
    expect(PerfilNavi.fromJson(_faisca.toJson()), _faisca);
    expect(PerfilNavi.fromJson({'nome': 'X', 'elemento': 'plasma', 'tracos': ['calma']}), isNull);
    expect(PerfilNavi.fromJson({'nome': ' ', 'elemento': 'ar', 'tracos': ['calma']}), isNull);
  });

  test('conta nova sem NAVI pede para criar; salvar manda para a API', () async {
    final api = ApiCodice('https://api.codice.test', cliente: apiFalsa());
    final sessao = Sessao(api: api);
    await api.registrar('ana', 'senha-boa-123', manter: true);
    await sessao.aoEntrar(manter: true);
    expect(sessao.conectado, isTrue);
    expect(sessao.temNavi, isFalse);

    await sessao.salvarPerfil(_faisca);
    expect(sessao.temNavi, isTrue);
    expect((await api.lerPerfil()).navi, _faisca);
  });

  test('"manter conectado" volta direto com o NAVI da conta', () async {
    final cliente = apiFalsa(inicial: _faisca);
    final api = ApiCodice('https://api.codice.test', cliente: cliente);
    await api.entrar('ana', 'senha-boa-123', manter: true);
    await Sessao(api: api).aoEntrar(manter: true);

    // "Reabre o app": instâncias novas, mesmo armazenamento seguro.
    final reaberta = Sessao(
      api: ApiCodice('https://api.codice.test', cliente: cliente),
    );
    expect(await reaberta.restaurada, isTrue);
    expect(reaberta.perfil, _faisca);
    expect(reaberta.usuario, 'ana');
  });

  test('sem "manter conectado", nada fica gravado para a próxima vez', () async {
    final cliente = apiFalsa(inicial: _faisca);
    final api = ApiCodice('https://api.codice.test', cliente: cliente);
    await api.entrar('ana', 'senha-boa-123', manter: false);
    final sessao = Sessao(api: api);
    await sessao.aoEntrar(manter: false);
    expect(sessao.perfil, _faisca); // vale enquanto o app está aberto

    final reaberta = Sessao(
      api: ApiCodice('https://api.codice.test', cliente: cliente),
    );
    expect(await reaberta.restaurada, isFalse);
    expect(reaberta.perfil, PerfilNavi.padrao);
  });

  test('sair esquece a sessão e o NAVI da conta', () async {
    final api = ApiCodice('https://api.codice.test', cliente: apiFalsa(inicial: _faisca));
    await api.entrar('ana', 'senha-boa-123');
    final sessao = Sessao(api: api);
    await sessao.aoEntrar(manter: true);
    await sessao.sair();
    expect(sessao.conectado, isFalse);
    expect(sessao.perfil, PerfilNavi.padrao);
    expect(await api.lerToken(), isNull);
  });
}
