import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/status_bar.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/ui/imagens.dart';
import 'package:codice_app/services/leitura_diario.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  /// Abaixo disso ela "ainda não entende" e o botão guardar fica travado.
  static const int minimoPalavras = 5;

  /// Palavras que acendem cada etiqueta. É a leitura dela: simples,
  /// previsível e sem IA — só o que você escreveu.
  /// Cada pista é o COMEÇO de uma palavra: "bia" acende com "Bia", mas
  /// não com "sabia"; "trabalh" pega "trabalho" e "trabalhei".
  final _leitura = LeituraDiario();

  final TextEditingController _texto = TextEditingController();
  final FocusNode _foco = FocusNode();

  /// Começa com uma memória antiga de propósito: é ela que permite
  /// demonstrar a contradição ("você mudou de emprego?").
  final List<Memoria> _memorias = [
    Memoria('Trabalho na livraria do centro.', {'emprego'},
        DateTime(2026, 9, 1)),
  ];

  final Set<String> _removidas = {}; // sugeridas que a pessoa recusou
  final Set<String> _extras = {}; // criadas à mão pelo "+"

  int _palavras = 0;
  bool _processando = false;
  Humor _humor = Humor.esperando;
  String _fala = 'oi. me conta como foi o dia — eu só sei o que você me ensina.';
  double _conhecimento = 0.22; // barra "rumo aos 14 anos"
  int _carinhos = 0;
  bool _pulando = false;
  Timer? _voltarAoNormal;
  Timer? _fimDoPulo;

  /// A pergunta da contradição ficou para depois porque a pessoa saiu
  /// do Diário antes dela aparecer (o IndexedStack mantém esta tela viva).
  bool _contradicaoPendente = false;

  @override
  void initState() {
    super.initState();
    // Foco também é evento: a borda da página acende quando o campo
    // ganha foco e apaga quando perde.
    _foco.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Visibility.of registra dependência: este método roda de novo quando
  /// a aba do Diário aparece ou some. Se havia pergunta guardada, ela sai
  /// agora — nunca por cima de outra aba.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contradicaoPendente && Visibility.of(context)) {
      _contradicaoPendente = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _perguntarContradicao();
      });
    }
  }

  @override
  void dispose() {
    _voltarAoNormal?.cancel();
    _fimDoPulo?.cancel();
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------- estado lido

  bool get _podeGuardar => _palavras >= minimoPalavras && !_processando;

  Set<String> get _detectadas => _leitura.detectar(_texto.text);

  Set<String> get _etiquetas =>
      {..._detectadas.difference(_removidas), ..._extras};



  // ------------------------------------------------------------- respostas

  /// A Frost fala. Um evento novo cancela o timer do anterior: quem
  /// chega por último vence, então dois toques rápidos nunca embaralham
  /// as falas (eventos concorrentes tratados de forma previsível).
  void _falar(String texto, Humor humor) {
    _voltarAoNormal?.cancel();
    setState(() {
      _fala = texto;
      _humor = humor;
      _pulando = true;
    });
    _fimDoPulo?.cancel();
    _fimDoPulo = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pulando = false);
    });
    _voltarAoNormal = Timer(const Duration(seconds: 5), () {
      if (!mounted || _processando) return;
      setState(() {
        _humor = _palavras == 0 ? Humor.esperando : Humor.lendo;
      });
    });
  }

  /// SnackBar única: esconde a anterior antes de mostrar a nova, para os
  /// avisos não formarem fila e o último evento ser sempre o que aparece.
  void _avisar(
    String mensagem, {
    IconData icone = Icons.info_outline,
    SnackBarAction? acao,
  }) {
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF211B3A),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF4A3A76)),
        ),
        content: Row(
          children: [
            Icon(icone, color: kPurple, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        action: acao,
      ),
    );
  }

  // ---------------------------------------------- 1. entrada em tempo real

  void _aoDigitar(String valor) {
    final antes = _palavras;
    final agora = _leitura.contarPalavras(valor);
    debugPrint('[Diário] onChanged: $agora palavras');

    setState(() {
      _palavras = agora;
      if (!_processando) {
        _humor = agora == 0 ? Humor.esperando : Humor.lendo;
      }
    });

    // Encadeamento: cruzar o limite em qualquer direção faz ela reagir.
    if (antes < minimoPalavras && agora >= minimoPalavras) {
      _falar('agora eu entendi o suficiente pra guardar.', Humor.curiosa);
    } else if (antes >= minimoPalavras && agora < minimoPalavras && agora > 0) {
      _falar('hm, ficou curto de novo.', Humor.pensando);
    }
  }

  // ------------------------------------------ 2. ação principal (guardar)

  Future<void> _guardar() async {
    if (!_podeGuardar) return; // defesa extra: o botão já vem travado
    debugPrint('[Diário] onPressed guardar → validando');
    _foco.unfocus();

    // Trava enquanto o fluxo não termina: toque duplo no botão não cria
    // duas memórias, e os outros controles esperam a vez.
    setState(() => _processando = true);

    final texto = _texto.text.trim();
    final etiquetas = _etiquetas;

    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kLine),
        ),
        title: const Text(
          'Posso guardar isso?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '«$texto»',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE4E0E9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              etiquetas.isEmpty
                  ? 'sem etiqueta — vai como "geral".'
                  : 'etiquetas: ${etiquetas.join(', ')}',
              style: const TextStyle(color: kPurple2, fontSize: 11),
            ),
            const SizedBox(height: 6),
            const Text(
              'nada vira memória sem você confirmar.',
              style: TextStyle(color: Color(0xFF8B8498), fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ainda não'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPurple,
              foregroundColor: const Color(0xFF171322),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('pode guardar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmou != true) {
      setState(() => _processando = false);
      _falar('tá bom. continuo só lendo.', Humor.pensando);
      return;
    }

    // Processamento simulado: dá tempo de ver que ela está "lendo".
    setState(() {
      _humor = Humor.lendo;
      _fala = 'lendo...';
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final contradiz = etiquetas.contains('emprego') &&
        _memorias.any((m) => m.etiquetas.contains('emprego'));
    final nova = Memoria(
      texto,
      etiquetas.isEmpty ? {'geral'} : etiquetas,
      DateTime.now(),
    );

    setState(() {
      _memorias.insert(0, nova);
      final subiu = _conhecimento + 0.08;
      _conhecimento = subiu > 1 ? 1.0 : subiu;
      _texto.clear();
      _palavras = 0;
      _removidas.clear();
      _extras.clear();
      _processando = false;
    });

    _falar(
      'guardei. agora eu sei ${_memorias.length} coisas sobre você.',
      Humor.feliz,
    );
    _avisar(
      'memória guardada · ${nova.etiquetas.join(', ')}',
      icone: Icons.bookmark_added_outlined,
      acao: SnackBarAction(
        label: 'ver',
        textColor: kPurple,
        onPressed: _abrirMemorias, // encadeamento: aviso → lista
      ),
    );

    // Encadeamento automático: se o fato novo bate de frente com um
    // antigo, ela pergunta sozinha, sem ninguém apertar nada.
    if (contradiz) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      // Se a pessoa trocou de aba nesse meio-tempo, a pergunta espera ela
      // voltar (ver didChangeDependencies).
      if (Visibility.of(context)) {
        await _perguntarContradicao();
      } else {
        _contradicaoPendente = true;
      }
    }
  }

  Future<void> _perguntarContradicao() async {
    // A memória nova está no índice 0; a antiga é a próxima de emprego.
    final antigas =
        _memorias.skip(1).where((m) => m.etiquetas.contains('emprego'));
    if (antigas.isEmpty) return;
    final antiga = antigas.first;
    _falar('espera... isso não bate com o que eu sabia.', Humor.confusa);

    final mudou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF36250D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF5B411B)),
        ),
        icon: const Icon(Icons.favorite_border, color: Color(0xFFF0B74B)),
        title: const Text(
          '«Você mudou de emprego?»',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'antes você me contou: «${antiga.texto}»\n\n'
          'dois fatos que eu guardo se contradizem.',
          style: const TextStyle(color: Color(0xFFD9CBB4), fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'não, é o mesmo',
              style: TextStyle(color: Color(0xFFF0B74B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF0B74B),
              foregroundColor: const Color(0xFF251A09),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('sim, mudei'),
          ),
        ],
      ),
    );

    if (!mounted || mudou == null) return;
    if (mudou) setState(() => _memorias.remove(antiga));
    _falar(
      mudou
          ? 'anotado. troquei o que eu sabia.'
          : 'ok. os dois continuam valendo.',
      mudou ? Humor.feliz : Humor.pensando,
    );
    _avisar(
      mudou ? 'memória antiga substituída' : 'as duas memórias foram mantidas',
      icone: Icons.sync_alt,
    );
  }

  // --------------------------------------------- 3. ação secundária (apagar)

  /// Toque curto só explica. Apagar é destrutivo, então exige um gesto
  /// que não acontece por acidente (e-book: "um botão chamado Excluir
  /// deve solicitar confirmação antes de agir").
  void _dicaApagar() {
    debugPrint('[Diário] onPressed apagar → só dica');
    _avisar(
      _texto.text.isEmpty
          ? 'não tem nada para apagar.'
          : 'segure o botão para apagar — assim nada some sem querer.',
      icone: Icons.touch_app_outlined,
    );
  }

  void _apagar() {
    debugPrint('[Diário] onLongPress apagar');
    final backup = _texto.text;
    if (backup.isEmpty) {
      _avisar('não tem nada para apagar.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _texto.clear();
      _palavras = 0;
      _removidas.clear();
      _extras.clear();
    });
    _falar('apagou? tudo bem, eu ainda não tinha guardado.', Humor.pensando);
    _avisar(
      'texto apagado',
      icone: Icons.delete_outline,
      acao: SnackBarAction(
        label: 'desfazer',
        textColor: kPurple,
        onPressed: () {
          // Se já escreveu outra coisa, desfazer não pode atropelar.
          if (_texto.text.isNotEmpty) {
            _avisar('você já escreveu outra coisa — o texto antigo não '
                'voltou para não apagar o novo.');
            return;
          }
          _texto.value = TextEditingValue(
            text: backup,
            selection: TextSelection.collapsed(offset: backup.length),
          );
          // Mudança feita por código não dispara onChanged — o evento
          // é encadeado à mão para o contador e as etiquetas voltarem.
          _aoDigitar(backup);
        },
      ),
    );
  }

  // --------------------------------------------------- 4. gestos na Frost

  void _tocarFrost() {
    debugPrint('[Diário] onTap na Frost');
    if (_processando) return;
    final n = _palavras;
    final falta = minimoPalavras - n;
    final String fala;
    if (n == 0) {
      fala = 'tô esperando você escrever. pode ser pouco.';
    } else if (falta > 0) {
      fala = 'li $n ${n == 1 ? 'palavra' : 'palavras'}. '
          'me conta mais $falta?';
    } else {
      final e = _etiquetas;
      fala = 'entendi: ${e.isEmpty ? 'um dia comum' : e.join(', ')}. '
          'posso guardar?';
    }
    _falar(fala, Humor.curiosa);
  }

  void _carinhoFrost() {
    debugPrint('[Diário] onDoubleTap na Frost');
    if (_processando) return;
    setState(() => _carinhos++);
    _falar(
      _carinhos == 1 ? 'hehe. isso foi um carinho?' : 'de novo! ($_carinhos)',
      Humor.feliz,
    );
  }

  void _segurarFrost() {
    debugPrint('[Diário] onLongPress na Frost');
    if (_processando) return;
    HapticFeedback.selectionClick();
    _abrirMemorias();
  }

  void _abrirMemorias() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kPanel,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'o que a Frost sabe (${_memorias.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'só o que você confirmou.',
              style: TextStyle(color: Color(0xFF8B8498), fontSize: 10),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _memorias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CartaoMemoria(_memorias[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ etiquetas

  void _alternarEtiqueta(String nome) {
    debugPrint('[Diário] onTap etiqueta "$nome"');
    setState(() {
      if (_extras.contains(nome)) {
        _extras.remove(nome);
      } else if (_removidas.contains(nome)) {
        _removidas.remove(nome);
      } else {
        _removidas.add(nome);
      }
    });
    final ativa = _etiquetas.contains(nome);
    _falar(
      ativa ? 'ok, é sobre $nome.' : 'entendi, não é sobre $nome.',
      Humor.pensando,
    );
  }

  Future<void> _novaEtiqueta() async {
    // O controller não é descartado aqui de propósito: o diálogo ainda
    // usa o campo durante a animação de saída.
    final campo = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text(
          'nova etiqueta',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: campo,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'ex: família'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, campo.text.trim()),
            child: const Text('adicionar'),
          ),
        ],
      ),
    );
    if (!mounted || nome == null || nome.isEmpty) return;
    setState(() => _extras.add(nome));
    _falar('$nome. vou lembrar dessa palavra.', Humor.curiosa);
  }

  // ----------------------------------------------------------------- tela

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    BotaoMenu(),
                    Text(
                      'Diário',
                      style: TextStyle(color: Color(0xFF8D8996), fontSize: 14),
                    ),
                    Spacer(),
                    StatusBar(),
                  ],
                ),
                const SizedBox(height: 20),
                _cabecalho(),
                const SizedBox(height: 14),
                _frostQueLe(),
                const SizedBox(height: 14),
                _pagina(),
                const SizedBox(height: 16),
                _secaoEtiquetas(),
                const SizedBox(height: 16),
                _aviso(),
              ],
            ),
          ),
        ),
        _rodape(),
      ],
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diário',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dataDeHoje(),
                style: const TextStyle(color: Color(0xFF77727F), fontSize: 10),
              ),
            ],
          ),
        ),
        // Atalho para a mesma lista do long press na Frost.
        InkWell(
          onTap: _abrirMemorias,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF211A3B),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF45356F)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmarks_outlined, color: kPurple, size: 13),
                const SizedBox(width: 5),
                Text(
                  '${_memorias.length} memórias',
                  style: const TextStyle(
                    color: kPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Seção da Frost: a área de gestos e o balão onde ela responde.
  Widget _frostQueLe() {
    final cor = _corDoHumor(_humor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _tocarFrost,
              onDoubleTap: _carinhoFrost,
              onLongPress: _segurarFrost,
              child: AnimatedScale(
                scale: _pulando ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111624),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: cor, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(
                      image: frostRostoImage,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1924),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border.all(color: cor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_iconeDoHumor(_humor), color: cor, size: 12),
                        const SizedBox(width: 5),
                        const Text(
                          'Frost · 8 anos',
                          style: TextStyle(
                            color: Color(0xFFB8B2C5),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_carinhos > 0) ...[
                          const Icon(Icons.favorite,
                              color: Color(0xFFFF8FB1), size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '$_carinhos',
                            style: const TextStyle(
                              color: Color(0xFFFF8FB1),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _fala,
                      style: const TextStyle(
                        color: Color(0xFFE5E1EA),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Flexible + ellipsis: com fonte do sistema maior ou tela
            // estreita, a dica encolhe em vez de estourar a linha.
            const Flexible(
              child: Text(
                'toque · dois toques · segure',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF6F6A7C), fontSize: 8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _conhecimento,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF2A2640),
                  color: const Color(0xFF65D6D6),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'rumo aos 14',
              style: TextStyle(color: Color(0xFF8D879B), fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  /// A página do diário: o campo de texto e o contador ao vivo.
  Widget _pagina() {
    final falta = minimoPalavras - _palavras;
    final pronto = falta <= 0;
    final corStatus = pronto ? const Color(0xFF52D9A2) : const Color(0xFFF0B74B);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1924),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _foco.hasFocus ? const Color(0xFF4A3A76) : const Color(0xFF302D3B),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _texto,
              focusNode: _foco,
              enabled: !_processando,
              onChanged: _aoDigitar,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              cursorColor: kPurple,
              style: const TextStyle(
                color: Color(0xFFE4E0E9),
                fontSize: 13,
                height: 1.55,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(top: 6),
                hintText: 'Acordei mal de novo, não preguei o olho. '
                    'A prova de física ficou pra quinta...',
                hintStyle: TextStyle(
                  color: Color(0xFF5E5869),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFF2D2937)),
          Row(
            children: [
              Text(
                '$_palavras ${_palavras == 1 ? 'palavra' : 'palavras'}',
                style: const TextStyle(
                  color: Color(0xFF888294),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                pronto ? Icons.check_circle_outline : Icons.hourglass_empty,
                color: corStatus,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  pronto
                      ? 'ela já consegue guardar'
                      : 'faltam $falta para ela entender',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secaoEtiquetas() {
    final detectadas = _detectadas;
    final nomes = [...detectadas, ..._extras.where((e) => !detectadas.contains(e))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ETIQUETAS SUGERIDAS',
          style: TextStyle(
            color: Color(0xFF8D879B),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (nomes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(
                  'aparecem enquanto você escreve',
                  style: TextStyle(color: Color(0xFF6F6A7C), fontSize: 10),
                ),
              ),
            for (final nome in nomes)
              _Etiqueta(
                nome: nome,
                ativa: _etiquetas.contains(nome),
                onTap: _processando ? null : () => _alternarEtiqueta(nome),
              ),
            InkWell(
              onTap: _processando ? null : _novaEtiqueta,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B3A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF493A70)),
                ),
                child: const Icon(Icons.add, color: kPurple, size: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aviso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF211F2B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF302D3B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_outlined, color: Color(0xFF8F899B), size: 17),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'escreva solto, do tamanho que der\n',
                    style: TextStyle(
                      color: Color(0xFFE2DEE8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'de madrugada, carregando, ela lê o dia e propõe '
                        'fatos. nada vira memória sem você confirmar.',
                    style: TextStyle(
                      color: Color(0xFF777181),
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rodapé fixo, fora da rolagem: as duas ações ficam sempre à mão.
  Widget _rodape() {
    final falta = minimoPalavras - _palavras;

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 6, 17, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                // null = desabilitado: a condição fica visível no próprio
                // botão em vez de virar um erro depois do clique.
                onPressed: _podeGuardar ? _guardar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: const Color(0xFF171322),
                  disabledBackgroundColor: const Color(0xFF2A2640),
                  disabledForegroundColor: const Color(0xFF7D778A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _processando
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFB9B3C3),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'guardando...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        falta > 0
                            ? 'escreva mais $falta ${falta == 1 ? 'palavra' : 'palavras'}'
                            : 'guardar no diário',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: _processando ? null : _dicaApagar,
              onLongPress: _processando ? null : _apagar,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF211B3A),
                foregroundColor: kPurple,
                side: const BorderSide(color: Color(0xFF493A70)),
              ),
              child: const Icon(Icons.delete_outline, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ auxiliares

  static Color _corDoHumor(Humor h) => switch (h) {
        Humor.esperando => const Color(0xFF302D3B),
        Humor.lendo => kPurple,
        Humor.curiosa => const Color(0xFF65D6D6),
        Humor.feliz => const Color(0xFFFF8FB1),
        Humor.confusa => const Color(0xFFF0B74B),
        Humor.pensando => const Color(0xFF8D879B),
      };

  static IconData _iconeDoHumor(Humor h) => switch (h) {
        Humor.esperando => Icons.more_horiz,
        Humor.lendo => Icons.menu_book_outlined,
        Humor.curiosa => Icons.lightbulb_outline,
        Humor.feliz => Icons.favorite,
        Humor.confusa => Icons.help_outline,
        Humor.pensando => Icons.psychology_outlined,
      };

  static String _dataDeHoje() {
    const dias = [
      'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
    ];
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
      'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final d = DateTime.now();
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }
}

/// Etiqueta tocável. InkWell em vez de GestureDetector porque aqui o
/// retorno visual do toque (a onda) já é parte do feedback.
class _Etiqueta extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback? onTap;

  const _Etiqueta({required this.nome, required this.ativa, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Ink(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ativa ? const Color(0xFF241D40) : const Color(0xFF211F2B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: ativa ? const Color(0xFF6A56B8) : const Color(0xFF373342),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ativa ? Icons.check : Icons.close,
              size: 11,
              color: ativa ? kPurple : const Color(0xFF6F6A7C),
            ),
            const SizedBox(width: 4),
            Text(
              nome,
              style: TextStyle(
                color: ativa ? const Color(0xFFD9D2F5) : const Color(0xFF6F6A7C),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                decoration: ativa ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoMemoria extends StatelessWidget {
  final Memoria memoria;

  const _CartaoMemoria(this.memoria);

  @override
  Widget build(BuildContext context) {
    final q = memoria.quando;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1924),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF302D3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoria.texto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE4E0E9), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '${memoria.etiquetas.join(' · ')}  ·  ${q.day}/${q.month}',
            style: const TextStyle(color: kPurple2, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
