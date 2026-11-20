import 'dart:io';

import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_navicity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conversa de verdade com o servidor Go, para provar que a assinatura Ed25519
/// feita em Dart é aceita por ele. Só roda com o servidor no ar:
///   NAVICITY_TESTE_URL=http://127.0.0.1:8099 flutter test test/integracao_navicity_test.dart
void main() {
  final url = Platform.environment['NAVICITY_TESTE_URL'];

  setUp(() {
    // Libera a rede real: o flutter_test bloqueia HTTP por padrão.
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('registra, consulta a cidade e lê os fatos no servidor Go', () async {
    final api = ApiNavicity(url!);
    final situacao = await api.entrar(
      const PerfilNavi(
        nome: 'Teste',
        elemento: Elemento.eletrico,
        tracos: [Traco.curiosa, Traco.calma],
      ),
    );
    expect(situacao.apelido, isNotEmpty);
    expect(situacao.areas, contains('Praça dos Bipes'));

    final de_novo = await api.situacao();
    expect(de_novo.id, situacao.id);

    final fatos = await api.fatos();
    expect(fatos.cursor, greaterThanOrEqualTo(0));
  }, skip: url == null ? 'defina NAVICITY_TESTE_URL' : false);
}
