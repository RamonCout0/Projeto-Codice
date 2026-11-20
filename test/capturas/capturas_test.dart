// Gera capturas de tela do app em PNG, para conferir o visual sem celular.
//   CAPTURAS=1 flutter test --update-goldens test/capturas/capturas_test.dart
// As imagens saem em test/capturas/saida/ (fora do Git). Sem CAPTURAS=1 o
// teste é ignorado, para não atrasar a suíte normal.
import 'dart:convert';
import 'dart:io';

import 'package:codice_app/app/raiz.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/services/api_navicity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object corpo, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _carregarFontes() async {
  final raiz = Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/ferramentas/flutter';
  final pasta = '$raiz/bin/cache/artifacts/material_fonts';
  Future<void> carregar(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    for (final a in arquivos) {
      final f = File('$pasta/$a');
      if (f.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await loader.load();
  }

  await carregar('Roboto', [
    'Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf',
  ]);
  await carregar('MaterialIcons', ['MaterialIcons-Regular.otf']);
  // Inter: o motor lê o peso de dentro de cada arquivo de fonte.
  final inter = Directory('assets/fontes')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ttf'))
      .toList();
  final loader = FontLoader('Inter');
  for (final f in inter) {
    loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
}

CidadeNavi _cidadeFalsa() {
  const situacao = {
    'id': 7,
    'apelido': 'Karo',
    'area': 'Praça dos Bipes',
    'estado': 'ocioso',
    'agora_s': 7200,
    'areas': [
      {'id': 0, 'nome': 'Praça dos Bipes', 'tipo': 'praca', 'presentes': 3, 'voce': true},
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
          'cursor': 5,
          'agora_s': 7200,
          'fatos': [
            {'seq': 1, 'quando_s': 100, 'tipo': 'entrou', 'importancia': 'normal', 'area': 'Praça dos Bipes'},
            {'seq': 2, 'quando_s': 600, 'tipo': 'conheceu', 'importancia': 'marcante', 'area': 'Praça dos Bipes', 'outro': 'Zeta', 'lado': 'origem', 'afinidade': 61, 'tom': 'indiferente'},
            {'seq': 3, 'quando_s': 1500, 'tipo': 'conversou', 'importancia': 'normal', 'area': 'Praça dos Bipes', 'outro': 'Zeta', 'lado': 'origem', 'afinidade': 66, 'delta': 5},
            {'seq': 4, 'quando_s': 3000, 'tipo': 'conheceu', 'importancia': 'marcante', 'area': 'Biblioteca Velha', 'outro': 'Iris', 'outro_gm': true, 'lado': 'alvo', 'afinidade': 72, 'tom': 'amistoso'},
            {'seq': 5, 'quando_s': 6900, 'tipo': 'conversou', 'importancia': 'normal', 'area': 'Biblioteca Velha', 'outro': 'Iris', 'outro_gm': true, 'lado': 'alvo', 'afinidade': 76, 'delta': 4},
          ],
        });
      }),
    ),
  );
}

void main() {
  final ligado = Platform.environment['CAPTURAS'] == '1';
  final claro = Platform.environment['CAPTURAS_TEMA'] == 'claro';
  final sufixo = claro ? 'claro' : 'noturno';

  testWidgets('capturas das telas', (t) async {
    await _carregarFontes();
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    Future<void> tirar(String nome) async {
      await t.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('saida/${nome}_$sufixo.png'));
    }

    await t.pumpWidget(RaizCodice(cidade: _cidadeFalsa()));
    await t.pumpAndSettle();
    if (claro) {
      // Liga o tema claro como a pessoa faria: pelo ajuste.
      final ctx = t.element(find.byType(MaterialApp));
      final ajustes = Provider.of<Ajustes>(ctx, listen: false);
      await ajustes.alterar(() => ajustes.modoTema = ModoTema.claro);
      await t.pumpAndSettle();
    }
    await tirar('01_boas_vindas');

    await t.tap(find.text('criar meu NAVI'));
    await t.pumpAndSettle();
    await tirar('02_cadastro');
    await t.tap(find.text('entrar sem conta'));
    await t.pumpAndSettle();
    await tirar('03_home');

    for (final (aba, arq) in [
      ('Conversa', '04_conversa'),
      ('Diário', '05_diario'),
      ('Cidade', '06_cidade'),
      ('Encontros', '07_encontros'),
    ]) {
      await t.tap(find.text(aba).last);
      await tirar(arq);
    }
    await t.tap(find.text('Zeta'));
    await tirar('08_detalhe_navi');
    await t.tap(find.byTooltip('voltar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cidade').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Praça dos Bipes').first);
    await tirar('09_lugar');
    await t.tap(find.byTooltip('voltar'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('abrir menu').first);
    await tirar('10_menu');
    await t.tap(find.text('Configurações'));
    await tirar('11_configuracoes');
    await t.tap(find.byTooltip('voltar'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('abrir menu').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Personalidade'));
    await tirar('12_personalidade');
  }, skip: !ligado);
}
