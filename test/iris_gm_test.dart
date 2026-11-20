import 'dart:convert';
import 'dart:io';

import 'package:codice_app/services/api_codice.dart' show FalhaApi;
import 'package:codice_app/services/api_gm.dart';
import 'package:codice_app/tema/tema.dart';
import 'package:codice_app/views/iris_config_tela.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _chaveBoa = 'chave-do-dono';

http.Response _json(Object corpo, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> _iris({int soc = 70, String texto = 'Calma e curiosa.'}) => {
  'nome': 'Iris',
  'elemento': 'cyber',
  'tracos': {'coragem': 60, 'curiosidade': 85, 'paciencia': 90, 'sociabilidade': soc, 'agressividade': 5},
  'personalidade': texto,
};

/// Servidor falso que confere a chave, como o de verdade.
ApiGm _api(List<Map<String, Object?>> gravados) => ApiGm(
  endereco: 'http://100.98.182.120:8080',
  cliente: MockClient((r) async {
    if (r.headers['Authorization'] != 'Bearer $_chaveBoa') {
      return _json({'erro': 'chave de administrador inválida'}, 401);
    }
    if (r.method == 'PUT') {
      final corpo = jsonDecode(r.body) as Map<String, dynamic>;
      gravados.add(corpo);
      return _json({
        ..._iris(),
        'tracos': corpo['tracos'],
        'personalidade': corpo['personalidade'],
      });
    }
    return _json(_iris());
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lê e grava a configuração com a chave certa; a errada dá 401', () async {
    final gravados = <Map<String, Object?>>[];
    final api = _api(gravados);

    final c = await api.ler(' $_chaveBoa '); // espaços das cópias são ignorados
    expect(c.tracos['paciencia'], 90);
    expect(c.personalidade, 'Calma e curiosa.');

    final salva = await api.salvar(_chaveBoa, c.copiar(tracos: {...c.tracos, 'sociabilidade': 12}));
    expect(salva.tracos['sociabilidade'], 12);
    expect(gravados.single['tracos'], containsPair('sociabilidade', 12));

    await expectLater(
      api.ler('errada'),
      throwsA(isA<FalhaApi>().having((e) => e.mensagem, 'mensagem', contains('inválida'))),
    );
  });

  test('servidor com a rota desligada (404) explica o motivo', () async {
    final api = ApiGm(
      endereco: 'http://localhost:8080',
      cliente: MockClient((_) async => _json({'erro': 'rota não encontrada'}, 404)),
    );
    await expectLater(
      api.ler('x'),
      throwsA(isA<FalhaApi>().having((e) => e.mensagem, 'mensagem', contains('desligada'))),
    );
  });

  test('recusa endereço HTTP fora de localhost e do Tailscale', () async {
    final api = ApiGm(endereco: 'http://192.168.0.10:8080');
    await expectLater(api.ler('x'), throwsA(isA<FalhaApi>()));
  });

  testWidgets('a tela pede a chave, destrava, edita e salva', (t) async {
    t.view.physicalSize = const Size(1080, 2400); // celular comum
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final gravados = <Map<String, Object?>>[];
    await t.pumpWidget(MaterialApp(theme: criarTema(), home: IrisConfigTela(api: _api(gravados))));
    await t.pumpAndSettle();

    // Trancada: só o campo da chave. Chave errada mostra o erro.
    expect(find.text('Personalidade'), findsNothing);
    await t.enterText(find.byType(TextField), 'errada');
    await t.tap(find.text('entrar'));
    await t.pumpAndSettle();
    expect(find.textContaining('inválida'), findsOneWidget);

    await t.enterText(find.byType(TextField), _chaveBoa);
    await t.tap(find.text('entrar'));
    await t.pumpAndSettle();
    expect(find.text('COMPORTAMENTO'), findsOneWidget);
    expect(find.text('Sociabilidade'), findsOneWidget);

    // Muda um traço e o texto, e salva.
    final slider = find.byType(Slider).at(3); // sociabilidade
    await t.drag(slider, const Offset(-200, 0));
    await t.enterText(find.byType(TextField), 'Fala em rimas.');
    await t.ensureVisible(find.text('salvar'));
    await t.pumpAndSettle();
    await t.tap(find.text('salvar'));
    await t.pumpAndSettle();
    expect(gravados.single['personalidade'], 'Fala em rimas.');
    expect((gravados.single['tracos'] as Map)['sociabilidade'], lessThan(70));

    // A chave ficou guardada: reabrir a tela já entra destravada.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(MaterialApp(theme: criarTema(), home: IrisConfigTela(api: _api(gravados))));
    await t.pumpAndSettle();
    expect(find.text('COMPORTAMENTO'), findsOneWidget);
  });

  // Contra o servidor de verdade (só roda com a chave no ambiente).
  final url = Platform.environment['NAVICITY_TESTE_URL'];
  final chave = Platform.environment['NAVICITY_ADMIN_TOKEN'];
  test('configuração da Iris no servidor Go de verdade', () async {
    HttpOverrides.global = null;
    final api = ApiGm(endereco: url);
    final antes = await api.ler(chave!);
    final salva = await api.salvar(chave, antes); // grava o mesmo valor: não muda nada
    expect(salva.tracos, antes.tracos);
    await expectLater(api.ler('errada'), throwsA(isA<FalhaApi>()));
  }, skip: (url == null || chave == null) ? 'defina NAVICITY_TESTE_URL e NAVICITY_ADMIN_TOKEN' : false);
}
