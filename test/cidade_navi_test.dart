import 'dart:convert';

import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_navicity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _agora = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true);

http.Response _json(Object corpo, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _situacao({int agora = 3600, String area = 'Praça dos Bipes'}) => {
  'id': 42,
  'apelido': 'Karo',
  'area': area,
  'estado': 'ocioso',
  'agora_s': agora,
  'areas': [
    {'id': 0, 'nome': 'Praça dos Bipes', 'tipo': 'praca', 'presentes': 3, 'voce': true},
    {'id': 1, 'nome': 'Biblioteca Velha', 'tipo': 'biblioteca', 'presentes': 1, 'voce': false},
  ],
};

Map<String, Object?> _fato(
  int seq,
  int quando,
  String tipo, {
  String? outro,
  bool gm = false,
  String lado = 'origem',
  int? afinidade,
  int? delta,
  String? tom,
  String area = 'Praça dos Bipes',
}) => {
  'seq': seq,
  'quando_s': quando,
  'tipo': tipo,
  'importancia': 'normal',
  'area': area,
  'outro': ?outro,
  if (gm) 'outro_gm': true,
  if (outro != null) 'lado': lado,
  'afinidade': ?afinidade,
  'delta': ?delta,
  if (tom != null) 'tom': tom,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  CidadeNavi criar(MockClientHandler responder) => CidadeNavi(
    intervalo: const Duration(hours: 1),
    agora: () => _agora,
    fabrica: (conta) => ApiNavicity(
      'http://100.98.182.120:8080',
      conta: conta,
      cliente: MockClient(responder),
      agora: () => _agora,
    ),
  );

  test('monta lugares e encontros só com o que o servidor entrega', () async {
    final cidade = criar((pedido) async {
      if (pedido.method == 'POST') return _json(_situacao(), 201);
      if (pedido.url.path == '/cidade') return _json(_situacao());
      return _json({
        'cursor': 6,
        'agora_s': 3600,
        'fatos': [
          _fato(1, 0, 'entrou'),
          _fato(2, 600, 'conheceu', outro: 'Zeta', afinidade: 61, tom: 'indiferente', delta: null),
          _fato(3, 1200, 'conversou', outro: 'Zeta', afinidade: 66, delta: 5),
          _fato(4, 1800, 'recusou', outro: 'Pixel'),
          _fato(5, 2400, 'conheceu', outro: 'Iris', gm: true, lado: 'alvo', afinidade: 70, tom: 'amistoso'),
          _fato(6, 3000, 'partiu', area: 'Praça dos Bipes'),
        ],
      });
    });

    await cidade.conectar(PerfilNavi.padrao);
    expect(cidade.estado, EstadoCidade.conectada);

    expect(cidade.lugares.map((l) => l.nome), ['Praça dos Bipes', 'Biblioteca Velha']);
    expect(cidade.lugares.first.voce, isTrue);
    expect(cidade.lugares.first.descricao, '3 NAVIs aqui agora, incluindo o seu.');

    final e = cidade.encontros;
    // Quem só recusou (Pixel) não é um encontro; o mais recente vem primeiro.
    expect(e.map((n) => n.nome), ['Iris', 'Zeta']);
    expect(e.first.gm, isTrue);
    expect(e.first.cor, Elemento.cyber.cor);
    expect(e.first.afinidade, 70);
    expect(e.last.afinidade, 66); // o valor da última conversa
    expect(e.last.encontros, 2);
    expect(e.last.relato, contains('conversaram'));
    expect(e.last.quando, 'há 40 min'); // 3600 - 1200 = 2400 s
  });

  test('apelidos ficam guardados por conta', () async {
    final cidade = criar((p) async => p.method == 'POST'
        ? _json(_situacao(), 201)
        : p.url.path == '/cidade'
        ? _json(_situacao())
        : _json({'cursor': 2, 'agora_s': 3600, 'fatos': [_fato(2, 600, 'conheceu', outro: 'Zeta', afinidade: 61, tom: 'indiferente')]}));
    await cidade.conectar(PerfilNavi.padrao, conta: 'ana');
    await cidade.alterarApelido('Zeta', 'Faísca');
    expect(cidade.encontro('Zeta')?.comoChamar, 'Faísca');

    final outra = criar((p) async => p.method == 'POST'
        ? _json(_situacao(), 201)
        : p.url.path == '/cidade'
        ? _json(_situacao())
        : _json({'cursor': 2, 'agora_s': 3600, 'fatos': [_fato(2, 600, 'conheceu', outro: 'Zeta', afinidade: 61, tom: 'indiferente')]}));
    await outra.conectar(PerfilNavi.padrao, conta: 'ana');
    expect(outra.encontro('Zeta')?.comoChamar, 'Faísca'); // lido do aparelho

    final bia = criar((p) async => p.method == 'POST'
        ? _json(_situacao(), 201)
        : p.url.path == '/cidade'
        ? _json(_situacao())
        : _json({'cursor': 2, 'agora_s': 3600, 'fatos': [_fato(2, 600, 'conheceu', outro: 'Zeta', afinidade: 61, tom: 'indiferente')]}));
    await bia.conectar(PerfilNavi.padrao, conta: 'bia');
    expect(bia.encontro('Zeta')?.apelido, isNull); // outra conta, outro caderno
  });

  test('cidade fora do ar vira erro com mensagem, e tentar de novo funciona', () async {
    var ligada = false;
    final cidade = criar((pedido) async {
      if (!ligada) return http.Response('', 503);
      if (pedido.method == 'POST') return _json(_situacao(), 201);
      if (pedido.url.path == '/cidade') return _json(_situacao());
      return _json({'cursor': 0, 'agora_s': 3600, 'fatos': <Object>[]});
    });
    await cidade.conectar(PerfilNavi.padrao);
    expect(cidade.estado, EstadoCidade.erro);
    expect(cidade.erro, contains('indispon'));
    expect(cidade.lugares, isEmpty);

    ligada = true;
    await cidade.tentarDeNovo();
    expect(cidade.estado, EstadoCidade.conectada);
    expect(cidade.encontros, isEmpty);
  });

  test('se a cidade reiniciou, o NAVI entra de novo e a lista recomeça', () async {
    var reiniciou = false;
    final cidade = criar((pedido) async {
      if (pedido.method == 'POST') return _json(_situacao(agora: reiniciou ? 5 : 3600), 201);
      if (pedido.url.path == '/cidade') return _json(_situacao(agora: reiniciou ? 5 : 3600));
      return _json({
        'cursor': reiniciou ? 1 : 2,
        'agora_s': reiniciou ? 5 : 3600,
        'fatos': [
          if (!reiniciou) _fato(2, 600, 'conheceu', outro: 'Zeta', afinidade: 61, tom: 'indiferente'),
          if (reiniciou) _fato(1, 0, 'entrou'),
        ],
      });
    });
    await cidade.conectar(PerfilNavi.padrao);
    expect(cidade.encontros, hasLength(1));

    reiniciou = true;
    await cidade.atualizar();
    expect(cidade.encontros, isEmpty);
    expect(cidade.fatos.single.tipo, 'entrou');
  });
}
