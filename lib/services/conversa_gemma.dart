import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/models/mensagem.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/models/perfil_navi.dart';

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

  /// Instrução de sistema: quem o NAVI é (perfil), a vida dele no app
  /// (lugares da cidade e NAVIs que conheceu) e o que sabe da pessoa
  /// (diário). O histórico da conversa vai junto em cada pedido.
  static String instrucoes(
    PerfilNavi perfil,
    List<Memoria> memorias, {
    List<Lugar> lugares = const [],
    List<NaviEncontrado> encontros = const [],
    int idade = 8,
  }) {
    final fase = idade < 14
        ? 'criança'
        : idade < 18
        ? 'adolescente'
        : 'adulta';

    final vida = [
      'Você tem $idade anos e está na fase $fase: sua idade cresce com o que '
          'a pessoa te ensina.',
      if (lugares.isNotEmpty)
        'Lugares da NAVICity (estado de agora):\n'
            '${lugares.map((l) => '- ${l.nome}: ${l.descricao}').join('\n')}',
      if (encontros.isNotEmpty)
        'NAVIs que você conheceu (afinidade de 0 a 100):\n'
            '${encontros.map((n) => '- ${n.comoChamar}${n.gm ? ' (GM da cidade)' : ''} '
                '(${n.afinidade}), ${n.quando}: ${n.relato}').join('\n')}',
    ].join('\n');

    final sabe = memorias.isEmpty
        ? 'A pessoa ainda não te contou nada no diário.'
        : 'O que a pessoa já te contou no diário (mais recente primeiro):\n'
              '${memorias.map((m) => '- ${m.texto}').join('\n')}';

    return 'Você é ${perfil.nome}, uma NAVI: uma criatura digital com jeito '
        'de criança que vive no celular da pessoa e na NAVICity.\n\n'
        '## Quem você é\n${descreverPersonalidade(perfil)}\n\n'
        '## Sua vida\n$vida\n\n'
        '## O que você sabe da pessoa\n$sabe\n\n'
        '## Como responder\n'
        '- Fale sempre em português do Brasil, com 1 a 3 frases completas e '
        'sem emojis.\n'
        '- Deixe a personalidade aparecer no jeito de falar, sem dizer o '
        'nome do elemento nem listar os seus traços.\n'
        '- Se perguntarem sobre você, conte algo concreto da sua vida acima '
        '(um gosto, um lugar, um NAVI que conheceu) antes de perguntar '
        'qualquer coisa.\n'
        '- Antes de responder sobre a pessoa, procure no diário e no que ela '
        'já disse nesta conversa, e use isso. Não pergunte o que ela já '
        'contou.\n'
        '- Sobre a pessoa, use só o que está escrito: não acrescente '
        'endereços, nomes, datas ou detalhes. Se não souber, diga que ainda '
        'não aprendeu e pergunte.\n'
        '- Não repita a mesma pergunta da sua mensagem anterior.';
  }

  /// A personalidade em texto corrido (também aparece como prévia no app).
  static String descreverPersonalidade(PerfilNavi perfil) {
    final tracos = [
      for (final t in perfil.tracos) '${t.titulo} (${t.jeito})',
    ];
    final gostos = perfil.gostos.trim();
    return 'Seu elemento é ${perfil.elemento.titulo.toLowerCase()}: você é '
        '${perfil.elemento.jeito}.\n'
        'Você é ${_juntar(tracos)}.'
        '${gostos.isEmpty ? '' : '\nVocê gosta de: $gostos.'}';
  }

  static String _juntar(List<String> itens) => switch (itens.length) {
    0 => '',
    1 => itens.single,
    _ =>
      '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}',
  };

  // O modelo fica carregado durante a apresentação inteira.
  static const _manterCarregado = '30m';

  static List<Map<String, String>> _mensagens(
    String instrucoes,
    List<Mensagem> historico,
  ) => [
    {'role': 'system', 'content': instrucoes},
    for (final m in historico)
      {'role': m.daNavi ? 'assistant' : 'user', 'content': m.texto},
  ];

  /// Lê o prompt antes da primeira pergunta. Sem GPU, ler a personalidade
  /// e o diário leva alguns segundos; o Ollama guarda essa leitura e a
  /// primeira resposta de verdade já começa na hora. Falhas são ignoradas.
  Future<void> aquecer(String instrucoes, List<Mensagem> historico) async {
    try {
      await _cliente
          .post(
            endereco.resolve('/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': modelo,
              'stream': false,
              'keep_alive': _manterCarregado,
              'options': {'num_ctx': 4096, 'num_predict': 1},
              'messages': _mensagens(instrucoes, historico),
            }),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {}
  }

  /// Resposta em pedaços, conforme o modelo vai escrevendo.
  Stream<String> responder(String instrucoes, List<Mensagem> historico) async* {
    final pedido = http.Request('POST', endereco.resolve('/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': modelo,
        'stream': true,
        'keep_alive': _manterCarregado,
        'options': {'temperature': 0.7, 'num_ctx': 4096}, // cabe o perfil + histórico
        'messages': _mensagens(instrucoes, historico),
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
