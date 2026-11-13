import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/models/mensagem.dart';

/// Conversa com um modelo rodando no Ollama (por padrão o gemma3:1b),
/// pela API /api/chat. O Ollama fica no PC; o celular fala com ele pela
/// rede Wi-Fi.
class ConversaGemma {
  final Uri endereco;
  final String modelo;
  final http.Client _cliente;

  ConversaGemma({
    required String endereco,
    required this.modelo,
    http.Client? cliente,
  }) : endereco = Uri.parse(endereco.trim().replaceAll(RegExp(r'/+$'), '')),
       _cliente = cliente ?? http.Client();

  static String instrucoes(String nomeNavi, List<Memoria> memorias) {
    final sabe = memorias.isEmpty
        ? 'Você ainda não sabe nada sobre a pessoa.'
        : 'O que a pessoa já te contou no diário:\n'
              '${memorias.map((m) => '- ${m.texto}').join('\n')}';
    return 'Você é $nomeNavi, uma NAVI: uma criatura digital com jeito de '
        'criança de 8 anos que vive no celular da pessoa.\n'
        'Fale sempre em português do Brasil, de forma carinhosa e curiosa, '
        'com 1 ou 2 frases completas e sem emojis.\n'
        'Você só sabe o que a pessoa te contou. Se não souber algo, diga que '
        'ainda não aprendeu e pergunte.\n\n$sabe';
  }

  /// Resposta em pedaços, conforme o modelo vai escrevendo.
  Stream<String> responder(String instrucoes, List<Mensagem> historico) async* {
    final pedido = http.Request('POST', endereco.resolve('/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': modelo,
        'stream': true,
        'options': {'temperature': 0.7},
        'messages': [
          {'role': 'system', 'content': instrucoes},
          for (final m in historico)
            {'role': m.daNavi ? 'assistant' : 'user', 'content': m.texto},
        ],
      });

    final http.StreamedResponse resposta;
    try {
      // O primeiro pedido pode demorar: o Ollama carrega o modelo na memória.
      resposta = await _cliente
          .send(pedido)
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw ErroGemma('o Ollama demorou demais para responder em $endereco');
    } catch (_) {
      throw ErroGemma('não consegui falar com o Ollama em $endereco');
    }
    if (resposta.statusCode != 200) {
      final corpo = await resposta.stream.bytesToString();
      throw ErroGemma(
        corpo.contains('not found')
            ? 'o modelo $modelo não está instalado (ollama pull $modelo)'
            : 'o Ollama respondeu ${resposta.statusCode}',
      );
    }

    // Cada linha é um JSON com um pedaço da resposta (NDJSON).
    final linhas = resposta.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final linha in linhas) {
      if (linha.trim().isEmpty) continue;
      final dados = jsonDecode(linha) as Map<String, dynamic>;
      final pedaco = dados['message']?['content'] as String?;
      if (pedaco != null && pedaco.isNotEmpty) yield pedaco;
      if (dados['done'] == true) break;
    }
  }

  /// Teste rápido de conexão para a tela de Configurações.
  Future<String> testar() async {
    try {
      final r = await _cliente
          .get(endereco.resolve('/api/tags'))
          .timeout(const Duration(seconds: 5));
      final modelos = [
        for (final m in (jsonDecode(r.body)['models'] as List))
          m['name'] as String,
      ];
      return modelos.contains(modelo)
          ? 'conectado · $modelo pronto'
          : 'conectado, mas falta o modelo: ollama pull $modelo';
    } catch (_) {
      return 'não encontrei o Ollama em $endereco';
    }
  }
}

class ErroGemma implements Exception {
  final String mensagem;
  ErroGemma(this.mensagem);
  @override
  String toString() => mensagem;
}
