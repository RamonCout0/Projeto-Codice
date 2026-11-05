import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/services/leitura_diario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reconhece Bia no início da palavra e ignora sabia', () {
    final leitura = LeituraDiario();
    expect(leitura.detectar('Eu sabia disso'), isNot(contains('Bia')));
    expect(leitura.detectar('Bia estudou hoje'), containsAll(['Bia', 'prova']));
    expect(leitura.contarPalavras('  uma  nova\nmemória  '), 3);
  });

  test('notifica somente quando recebe um apelido válido', () {
    final estado = EstadoCodice();
    var avisos = 0;
    estado.addListener(() => avisos++);
    estado.alterarApelido('Pixel', ' ');
    estado.alterarApelido('Pixel', ' Faísca ');
    expect(avisos, 1);
    expect(estado.obterNavi('Pixel')?.comoChamar, 'Faísca');
    estado.dispose();
  });
}
