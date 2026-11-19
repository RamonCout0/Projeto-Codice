import 'package:codice_app/app/raiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre todas as abas num celular sem erro de layout', (t) async {
    t.view.physicalSize = const Size(1080, 2340); // celular comum
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    FlutterSecureStorage.setMockInitialValues({});

    await t.pumpWidget(const RaizCodice());
    await t.pumpAndSettle(); // confere a sessão guardada (não há nenhuma)
    await t.tap(find.text('criar meu NAVI'));
    await t.pumpAndSettle();
    expect(find.text('Confirmar senha'), findsOneWidget);
    await t.tap(find.text('entrar sem conta'));
    await t.pumpAndSettle();

    for (final aba in ['Conversa', 'Diário', 'Cidade', 'Encontros', 'Navi']) {
      await t.tap(find.text(aba).last);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'aba $aba');
    }

    await t.tap(find.text('Encontros').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Pixel'));
    await t.pumpAndSettle();
    expect(find.text('dar um apelido'), findsOneWidget);
  });
}
