import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/services/leitura_diario.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/views/diario/dialogos_diario.dart';
import 'package:codice_app/views/diario/etiquetas_diario.dart';
import 'package:codice_app/views/diario/navi_que_le.dart';
import 'package:codice_app/views/diario/pagina_diario.dart';
import 'package:codice_app/views/diario/rodape_diario.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

class DiarioTela extends StatefulWidget {
  const DiarioTela({super.key});

  @override
  State<DiarioTela> createState() => _DiarioTelaState();
}

class _DiarioTelaState extends State<DiarioTela> {
  /// Abaixo disso ela "ainda não entende" e o botão guardar fica travado.
  static const _minimoPalavras = 5;

  final _leitura = LeituraDiario();
  final _texto = TextEditingController();
  final _foco = FocusNode();

  /// As memórias ficam no EstadoCodice: a Conversa também usa.
  EstadoCodice get _estado => context.read<EstadoCodice>();
  List<Memoria> get _memorias => _estado.memorias;
  final _removidas = <String>{}; // sugeridas que a pessoa recusou
  final _extras = <String>{}; // criadas à mão pelo "+"

  int _palavras = 0;
  bool _processando = false;
  Humor _humor = Humor.esperando;
  String _fala =
      'oi. me conta como foi o dia — eu só sei o que você me ensina.';
  int _carinhos = 0;
  bool _pulando = false;
  Timer? _voltarAoNormal;
  Timer? _fimDoPulo;

  /// A pessoa saiu do Diário antes da pergunta aparecer: ela espera a
  /// aba voltar a ficar visível (ver didChangeDependencies).
  bool _contradicaoPendente = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {})); // borda acende com o foco
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contradicaoPendente && Visibility.of(context)) {
      _contradicaoPendente = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resolverContradicao();
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

  bool get _podeGuardar => _palavras >= _minimoPalavras && !_processando;
  Set<String> get _detectadas => _leitura.detectar(_texto.text);
  Set<String> get _etiquetas => {
    ..._detectadas.difference(_removidas),
    ..._extras,
  };

  void _avisar(
    String msg, {
    IconData icone = Icons.info_outline,
    SnackBarAction? acao,
  }) => avisar(context, msg, icone: icone, acao: acao);

  /// A NAVI fala. Um evento novo cancela o timer do anterior: quem chega
  /// por último vence, então toques rápidos nunca embaralham as falas.
  void _falar(String texto, Humor humor) {
    _voltarAoNormal?.cancel();
    _fimDoPulo?.cancel();
    setState(() {
      _fala = texto;
      _humor = humor;
      _pulando = true;
    });
    _fimDoPulo = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pulando = false);
    });
    _voltarAoNormal = Timer(const Duration(seconds: 5), () {
      if (!mounted || _processando) return;
      setState(() => _humor = _palavras == 0 ? Humor.esperando : Humor.lendo);
    });
  }

  void _limparRascunho() {
    _texto.clear();
    _palavras = 0;
    _removidas.clear();
    _extras.clear();
  }

  // ------------------------------------------------------------ digitação

  void _aoDigitar(String valor) {
    final antes = _palavras;
    final agora = _leitura.contarPalavras(valor);
    setState(() {
      _palavras = agora;
      if (!_processando) _humor = agora == 0 ? Humor.esperando : Humor.lendo;
    });
    // Cruzar o limite em qualquer direção faz ela reagir.
    if (antes < _minimoPalavras && agora >= _minimoPalavras) {
      _falar('agora eu entendi o suficiente pra guardar.', Humor.curiosa);
    } else if (antes >= _minimoPalavras &&
        agora < _minimoPalavras &&
        agora > 0) {
      _falar('hm, ficou curto de novo.', Humor.pensando);
    }
  }

  // --------------------------------------------------------------- guardar

  Future<void> _guardar() async {
    if (!_podeGuardar) return;
    _foco.unfocus();
    // Trava tudo até o fluxo terminar: toque duplo não cria duas memórias.
    setState(() => _processando = true);

    final texto = _texto.text.trim();
    final etiquetas = _etiquetas;
    final confirmou = await confirmarGuardar(context, texto, etiquetas);
    if (!mounted) return;
    if (confirmou != true) {
      setState(() => _processando = false);
      _falar('tá bom. continuo só lendo.', Humor.pensando);
      return;
    }

    setState(() {
      _humor = Humor.lendo;
      _fala = 'lendo...';
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final contradiz =
        etiquetas.contains('emprego') &&
        _memorias.any((m) => m.etiquetas.contains('emprego'));
    final nova = Memoria(
      texto,
      etiquetas.isEmpty ? {'geral'} : etiquetas,
      DateTime.now(),
    );
    setState(() {
      _estado.guardarMemoria(nova);
      _limparRascunho();
      _processando = false;
    });

    _falar(
      'guardei. agora eu sei ${_memorias.length} coisas sobre você.',
      Humor.feliz,
    );
    _avisar(
      'memória guardada · ${nova.etiquetas.join(', ')}',
      icone: Icons.bookmark_added_outlined,
      acao: SnackBarAction(label: 'ver', onPressed: _abrirMemorias),
    );

    // Se o fato novo bate de frente com um antigo, ela pergunta sozinha. A
    // pergunta fica guardada: se a pessoa sair daqui, a Home a mostra.
    if (contradiz) {
      final antiga = _memorias
          .skip(1)
          .where((m) => m.etiquetas.contains('emprego'))
          .first;
      _estado.perguntar(PerguntaPendente(antiga, 'emprego'));
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      if (Visibility.of(context)) {
        await _resolverContradicao();
      } else {
        _contradicaoPendente = true;
      }
    }
  }

  Future<void> _resolverContradicao() async {
    final pendente = _estado.pergunta;
    if (pendente == null) return;
    final antiga = pendente.antiga;
    _falar('espera... isso não bate com o que eu sabia.', Humor.confusa);

    final mudou = await perguntarContradicao(context, antiga);
    if (!mounted || mudou == null) return;
    if (mudou) _estado.esquecerMemoria(antiga);
    _estado.encerrarPergunta();
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

  // ---------------------------------------------------------------- apagar

  void _dicaApagar() => _avisar(
    _texto.text.isEmpty
        ? 'não tem nada para apagar.'
        : 'segure o botão para apagar — assim nada some sem querer.',
    icone: Icons.touch_app_outlined,
  );

  void _apagar() {
    final backup = _texto.text;
    if (backup.isEmpty) return _avisar('não tem nada para apagar.');
    HapticFeedback.mediumImpact();
    setState(_limparRascunho);
    _falar('apagou? tudo bem, eu ainda não tinha guardado.', Humor.pensando);
    _avisar(
      'texto apagado',
      icone: Icons.delete_outline,
      acao: SnackBarAction(
        label: 'desfazer',
        onPressed: () {
          // Se já escreveu outra coisa, desfazer não pode atropelar.
          if (_texto.text.isNotEmpty) {
            return _avisar(
              'você já escreveu outra coisa — o texto antigo '
              'não voltou para não apagar o novo.',
            );
          }
          _texto.value = TextEditingValue(
            text: backup,
            selection: TextSelection.collapsed(offset: backup.length),
          );
          // Mudança por código não dispara onChanged: chama à mão.
          _aoDigitar(backup);
        },
      ),
    );
  }

  // ------------------------------------------------------- gestos na NAVI

  void _tocarNavi() {
    if (_processando) return;
    final n = _palavras;
    final falta = _minimoPalavras - n;
    final e = _etiquetas;
    _falar(
      n == 0
          ? 'tô esperando você escrever. pode ser pouco.'
          : falta > 0
          ? 'li ${plural(n, 'palavra')}. me conta mais $falta?'
          : 'entendi: ${e.isEmpty ? 'um dia comum' : e.join(', ')}. posso guardar?',
      Humor.curiosa,
    );
  }

  void _carinhoNavi() {
    if (_processando) return;
    setState(() => _carinhos++);
    _falar(
      _carinhos == 1 ? 'hehe. isso foi um carinho?' : 'de novo! ($_carinhos)',
      Humor.feliz,
    );
  }

  void _segurarNavi() {
    if (_processando) return;
    HapticFeedback.selectionClick();
    _abrirMemorias();
  }

  void _abrirMemorias() => mostrarMemorias(context, _memorias);

  // ------------------------------------------------------------- etiquetas

  void _alternarEtiqueta(String nome) {
    setState(() {
      if (!_extras.remove(nome) && !_removidas.remove(nome))
        _removidas.add(nome);
    });
    _falar(
      _etiquetas.contains(nome)
          ? 'ok, é sobre $nome.'
          : 'entendi, não é sobre $nome.',
      Humor.pensando,
    );
  }

  Future<void> _novaEtiqueta() async {
    final nome = await pedirNovaEtiqueta(context);
    if (!mounted || nome == null || nome.isEmpty) return;
    setState(() => _extras.add(nome));
    _falar('$nome. vou lembrar dessa palavra.', Humor.curiosa);
  }

  // ------------------------------------------------------------------ tela

  @override
  Widget build(BuildContext context) {
    final detectadas = _detectadas;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Estilos.margem,
              0,
              Estilos.margem,
              12,
            ),
            children: [
              const CabecalhoAba('Diário'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diário', style: Estilos.titulo),
                        Text(_dataDeHoje(), style: Estilos.legenda),
                      ],
                    ),
                  ),
                  Pilula(
                    '${context.watch<EstadoCodice>().memorias.length} memórias',
                    icone: Icons.bookmarks_outlined,
                    onTap: _abrirMemorias,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              NaviQueLe(
                humor: _humor,
                fala: _fala,
                pulando: _pulando,
                carinhos: _carinhos,
                conhecimento: context.watch<EstadoCodice>().progressoIdade,
                aoTocar: _tocarNavi,
                aoTocarDuasVezes: _carinhoNavi,
                aoSegurar: _segurarNavi,
              ),
              const SizedBox(height: 14),
              PaginaDiario(
                texto: _texto,
                foco: _foco,
                habilitada: !_processando,
                aoDigitar: _aoDigitar,
                palavras: _palavras,
                minimo: _minimoPalavras,
              ),
              const SizedBox(height: 16),
              EtiquetasDiario(
                nomes: [
                  ...detectadas,
                  ..._extras.where((e) => !detectadas.contains(e)),
                ],
                ativas: _etiquetas,
                travadas: _processando,
                aoAlternar: _alternarEtiqueta,
                aoCriar: _novaEtiqueta,
              ),
              const SizedBox(height: 16),
              const DicaDiario(),
            ],
          ),
        ),
        RodapeDiario(
          faltam: _minimoPalavras - _palavras,
          processando: _processando,
          aoGuardar: _podeGuardar ? _guardar : null,
          aoTocarApagar: _dicaApagar,
          aoSegurarApagar: _apagar,
        ),
      ],
    );
  }
}

String _dataDeHoje() {
  const dias = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final d = DateTime.now();
  return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
}
