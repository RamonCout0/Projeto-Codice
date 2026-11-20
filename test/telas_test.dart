import 'dart:convert';

import 'package:codice_app/app/raiz.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/services/api_navicity.dart';
import 'package:codice_app/widgets/foto_navi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object corpo, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Uma cidade simulada: a Iris (GM) e o Zeta já foram conhecidos.
CidadeNavi _cidadeFalsa() {
  const situacao = {
    'id': 7,
    'apelido': 'Karo',
    'area': 'Praça dos Bipes',
    'estado': 'ocioso',
    'agora_s': 7200,
    'areas': [
      {'id': 0, 'nome': 'Praça dos Bipes', 'tipo': 'praca', 'presentes': 2, 'voce': true},
      {'id': 1, 'nome': 'Biblioteca Velha', 'tipo': 'biblioteca', 'presentes': 1, 'voce': false},
      {'id': 2, 'nome': 'Café da Esquina', 'tipo': 'cafe', 'presentes': 0, 'voce': false},
    ],
  };
  return CidadeNavi(
    intervalo: const Duration(hours: 1),
    fabrica: (conta) => ApiNavicity(
      'http://localhost:8080',
      conta: conta,
      cliente: MockClient((pedido) async {
        if (pedido.method == 'POST') return _json(situacao, 201);
        if (pedido.url.path == '/cidade') return _json(situacao);
        return _json({
          'cursor': 3,
          'agora_s': 7200,
          'fatos': [
            {
              'seq': 2, 'quando_s': 600, 'tipo': 'conheceu', 'importancia': 'marcante',
              'area': 'Praça dos Bipes', 'outro': 'Zeta', 'lado': 'origem',
              'afinidade': 61, 'tom': 'indiferente',
            },
            {
              'seq': 3, 'quando_s': 3000, 'tipo': 'conheceu', 'importancia': 'marcante',
              'area': 'Biblioteca Velha', 'outro': 'Iris', 'outro_gm': true, 'lado': 'alvo',
              'afinidade': 72, 'tom': 'amistoso',
            },
          ],
        });
      }),
    ),
  );
}

void main() {
  testWidgets('abre todas as abas num celular sem erro de layout', (t) async {
    t.view.physicalSize = const Size(1080, 2340); // celular comum
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await t.pumpWidget(RaizCodice(cidade: _cidadeFalsa()));
    await t.pumpAndSettle(); // confere a sessão guardada (não há nenhuma)
    await t.tap(find.text('criar meu NAVI'));
    await t.pumpAndSettle();
    expect(find.text('Confirmar senha'), findsOneWidget);
    await t.tap(find.text('entrar sem conta'));
    await t.pumpAndSettle();

    // Home: novidade real da cidade (o último fato) e nada de dado fixo.
    expect(find.textContaining('Iris puxou conversa com Frost'), findsOneWidget);
    expect(find.text('VIGOR'), findsNothing);
    expect(find.textContaining('mudou de emprego'), findsNothing);

    for (final aba in ['Conversa', 'Diário', 'Cidade', 'Encontros', 'Navi']) {
      await t.tap(find.text(aba).last);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'aba $aba');
    }

    await t.tap(find.text('Cidade').last);
    await t.pumpAndSettle();
    expect(find.text('Café da Esquina'), findsOneWidget);

    await t.tap(find.text('Encontros').last);
    await t.pumpAndSettle();
    expect(find.textContaining('Iris'), findsWidgets);
    // O selo de GM é um emblema no retrato da Iris (e só nela).
    expect(t.widgetList<FotoNavi>(find.byType(FotoNavi)).where((f) => f.gm).length, 1);
    await t.tap(find.text('Zeta'));
    await t.pumpAndSettle();
    expect(find.text('dar um apelido'), findsOneWidget);
  });
}
