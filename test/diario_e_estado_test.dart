import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/services/leitura_diario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reconhece Bia no início da palavra e ignora sabia', () {
    final leitura = LeituraDiario();
    expect(leitura.detectar('Eu sabia disso'), isNot(contains('Bia')));
    expect(leitura.detectar('Bia estudou hoje'), containsAll(['Bia', 'prova']));
    expect(leitura.contarPalavras('  uma  nova\nmemória  '), 3);
  });

  test('a NAVI começa sem memórias, com 8 anos e cresce com o diário', () {
    final estado = EstadoCodice();
    expect(estado.memorias, isEmpty);
    expect(estado.idade, 8);
    expect(estado.fase, 'criança');
    expect(estado.faltamParaCrescer, EstadoCodice.memoriasPorAno);

    for (var i = 0; i < EstadoCodice.memoriasPorAno; i++) {
      estado.guardarMemoria(Memoria('memória $i', {'geral'}, DateTime(2026, 11, 1)));
    }
    expect(estado.idade, 9);
    expect(estado.progressoIdade, 0);

    for (var i = 0; i < EstadoCodice.memoriasPorAno * 20; i++) {
      estado.guardarMemoria(Memoria('mais $i', {'geral'}, DateTime(2026, 11, 2)));
    }
    expect(estado.idade, EstadoCodice.idadeMaxima); // trava aos 18
    expect(estado.fase, 'adulta');
    expect(estado.faltamParaCrescer, 0);
    estado.dispose();
  });

  test('as memórias sobrevivem a fechar o app', () async {
    final a = EstadoCodice();
    a.guardarMemoria(Memoria('Tenho prova sexta.', {'prova'}, DateTime(2026, 11, 3)));
    await Future<void>.delayed(Duration.zero);

    final b = EstadoCodice();
    await b.carregar();
    expect(b.memorias.single.texto, 'Tenho prova sexta.');
    expect(b.memorias.single.etiquetas, {'prova'});
    a.dispose();
    b.dispose();
  });

  test('esquecer a memória antiga encerra a pergunta pendente', () {
    final estado = EstadoCodice();
    final antiga = Memoria('Trabalho na livraria.', {'emprego'}, DateTime(2026, 9, 1));
    estado.guardarMemoria(antiga);
    estado.perguntar(PerguntaPendente(antiga, 'emprego'));
    expect(estado.pergunta?.texto, 'Você mudou de emprego?');
    estado.esquecerMemoria(antiga);
    expect(estado.pergunta, isNull);
    estado.dispose();
  });

  test('apelidos só valem se não forem vazios e ficam guardados', () async {
    final cidade = CidadeNavi();
    var avisos = 0;
    cidade.addListener(() => avisos++);
    await cidade.alterarApelido('Zeta', ' ');
    expect(avisos, 0);
    await cidade.alterarApelido('Zeta', ' Faísca ');
    expect(avisos, 1);
    cidade.dispose();
  });
}
