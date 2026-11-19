import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:codice_app/models/mensagem.dart';
import 'package:codice_app/services/conversa_gemma.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Monta um .glb mínimo só com o bloco JSON.
File glbFalso(Directory pasta, String nome, Map<String, dynamic> json) {
  final texto = [...utf8.encode(jsonEncode(json))];
  while (texto.length % 4 != 0) {
    texto.add(0x20);
  }
  final b = BytesBuilder()
    ..add(_u32(0x46546C67))
    ..add(_u32(2))
    ..add(_u32(20 + texto.length))
    ..add(_u32(texto.length))
    ..add(_u32(0x4E4F534A))
    ..add(texto);
  return File('${pasta.path}/$nome')..writeAsBytesSync(b.toBytes());
}

List<int> _u32(int v) => [
  v & 255,
  (v >> 8) & 255,
  (v >> 16) & 255,
  (v >> 24) & 255,
];

void main() {
  test('reconhece modelo VRM 1.0, animação VRMA e arquivo qualquer', () async {
    final pasta = Directory.systemTemp.createTempSync('codice');
    addTearDown(() => pasta.deleteSync(recursive: true));

    final modelo = await lerGlb(
      glbFalso(pasta, 'a.vrm', {
        'extensions': {
          'VRMC_vrm': {
            'meta': {'name': 'Alice'},
          },
        },
      }),
    );
    expect(modelo!.ehModelo, isTrue);
    expect(modelo.nomeModelo, 'Alice');

    final anim = await lerGlb(
      glbFalso(pasta, 'b.vrma', {
        'extensions': {'VRMC_vrm_animation': {}},
      }),
    );
    expect(anim!.ehAnimacao, isTrue);
    expect(anim.ehModelo, isFalse);

    final texto = File('${pasta.path}/c.txt')
      ..writeAsStringSync('oi, não sou glb');
    expect(await lerGlb(texto), isNull);
    expect(await ehFbx(texto), isFalse);
  });

  test('reconhece .fbx do Mixamo, binário e texto', () async {
    final pasta = Directory.systemTemp.createTempSync('codice');
    addTearDown(() => pasta.deleteSync(recursive: true));

    final binario = File('${pasta.path}/aceno.fbx')
      ..writeAsBytesSync([...'Kaydara FBX Binary  '.codeUnits, 0, 0x1a, 0]);
    final texto = File('${pasta.path}/parada.fbx')
      ..writeAsStringSync('; FBX 7.4.0 project file\n');
    expect(await ehFbx(binario), isTrue);
    expect(await ehFbx(texto), isTrue);
    expect(await lerGlb(binario), isNull);
  });

  test('junta os pedaços da resposta do Ollama e manda o histórico', () async {
    late Map<String, dynamic> enviado;
    final cliente = MockClient.streaming((pedido, corpo) async {
      enviado = jsonDecode(await corpo.bytesToString());
      final linhas = [
        {
          'message': {'content': 'oi, '},
          'done': false,
        },
        {
          'message': {'content': 'tudo bem?'},
          'done': true,
        },
      ].map((l) => '${jsonEncode(l)}\n');
      return http.StreamedResponse(
        Stream.value(utf8.encode(linhas.join())),
        200,
      );
    });

    final gemma = ConversaGemma(
      endereco: 'http://pc:11434/',
      modelo: 'gemma3:1b',
      cliente: cliente,
    );
    final pedacos = await gemma.responder('instruções', [
      Mensagem.daNavi('olá'),
      Mensagem.daPessoa('oi'),
    ]).toList();

    expect(pedacos.join(), 'oi, tudo bem?');
    expect(enviado['model'], 'gemma3:1b');
    final roles = [for (final m in enviado['messages'] as List) m['role']];
    expect(roles, ['system', 'assistant', 'user']);
  });

  test('erro claro quando o modelo não está instalado', () async {
    final cliente = MockClient(
      (_) async => http.Response('model "x" not found', 404),
    );
    final gemma = ConversaGemma(
      endereco: 'http://pc:11434',
      modelo: 'x',
      cliente: cliente,
    );
    expect(
      gemma.responder('', []).toList(),
      throwsA(
        isA<ErroGemma>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('ollama pull x'),
        ),
      ),
    );
  });
}
