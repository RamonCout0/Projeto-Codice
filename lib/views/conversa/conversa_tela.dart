import 'dart:async';
import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/models/mensagem.dart';
import 'package:codice_app/services/conversa_gemma.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/views/conversa/partes_conversa.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/icones.dart';

class ConversaTela extends StatefulWidget {
  const ConversaTela({super.key});

  @override
  State<ConversaTela> createState() => _ConversaTelaState();
}

class _ConversaTelaState extends State<ConversaTela> {
  final _mensagens = [
    Mensagem.daNavi('oi! me conta alguma coisa. eu aprendo com você.'),
  ];
  final _campo = TextEditingController();
  final _rolagem = ScrollController();
  bool _respondendo = false;
  bool _falando = false;
  Humor _humor = Humor.esperando;

  // O Gemma escreve mais rápido do que alguém fala. O texto que chega vai
  // para uma fila e aparece em ritmo de fala, para a boca acompanhar.
  static const _porLetra = Duration(milliseconds: 40); // ~25 letras/s
  static final _emoji = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}] ?',
    unicode: true,
  );
  String _fila = '';
  int _pausa = 0;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    // Assim que a aba existe, o Gemma já lê a personalidade e o diário.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _gemma().aquecer(_instrucoes(), _mensagens);
    });
  }

  ConversaGemma _gemma() {
    final ajustes = context.read<Ajustes>();
    return ConversaGemma(endereco: ajustes.enderecoOllama, modelo: ajustes.modelo);
  }

  /// Personalidade (elemento, traços, gostos), a vida do NAVI no app e o
  /// que o diário ensinou.
  String _instrucoes() {
    final estado = context.read<EstadoCodice>();
    return ConversaGemma.instrucoes(
      context.read<Sessao>().perfil,
      estado.memorias,
      idade: estado.idade,
      lugares: context.read<CidadeNavi>().lugares,
      encontros: context.read<CidadeNavi>().encontros,
    );
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Mostra a fila letra a letra em [resposta]. Termina quando a fila
  /// esvazia e [acabou] retorna true.
  Future<void> _falarAos(Mensagem resposta, bool Function() acabou) {
    final pronto = Completer<void>();
    _relogio?.cancel();
    _relogio = Timer.periodic(_porLetra, (relogio) {
      if (!mounted) {
        relogio.cancel();
        if (!pronto.isCompleted) pronto.complete();
        return;
      }
      if (_pausa > 0) {
        _pausa--;
        return;
      }
      if (_fila.isEmpty) {
        if (acabou()) {
          relogio.cancel();
          if (!pronto.isCompleted) pronto.complete();
        }
        return;
      }
      // Uma letra (duas unidades quando for um par substituto).
      final tamanho =
          _fila.length > 1 && (_fila.codeUnitAt(0) & 0xFC00) == 0xD800 ? 2 : 1;
      final letra = _fila.substring(0, tamanho);
      _fila = _fila.substring(tamanho);
      // Respira um pouco na pontuação, como quem fala.
      _pausa = switch (letra) {
        '.' || '!' || '?' => 7,
        ',' || ';' || ':' => 3,
        _ => 0,
      };
      setState(() {
        resposta.texto += letra;
        _falando = true;
        _humor = Humor.esperando;
      });
      _rolarParaOFim();
    });
    return pronto.future;
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.animateTo(
          _rolagem.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _campo.text.trim();
    if (texto.isEmpty || _respondendo) return;
    _campo.clear();

    final gemma = _gemma();
    final instrucoes = _instrucoes();
    final historico = [..._mensagens, Mensagem.daPessoa(texto)];
    final resposta = Mensagem.daNavi('');

    setState(() {
      _mensagens
        ..add(historico.last)
        ..add(resposta);
      _respondendo = true;
      _humor = Humor.pensando;
    });
    _rolarParaOFim();

    _fila = '';
    var recebeuTudo = false;
    final falando = _falarAos(resposta, () => recebeuTudo);
    try {
      await for (final pedaco in gemma.responder(instrucoes, historico)) {
        if (!mounted) return;
        // O gemma3:1b às vezes ignora o "sem emojis" do prompt.
        final limpo = pedaco.replaceAll(_emoji, '');
        // O começo da resposta costuma vir com espaços ou quebra de linha.
        _fila += resposta.texto.isEmpty && _fila.isEmpty
            ? limpo.trimLeft()
            : limpo;
      }
      recebeuTudo = true;
      await falando;
      resposta.texto = resposta.texto.trim();
      _humor = resposta.texto.endsWith('?') ? Humor.curiosa : Humor.feliz;
    } on ErroGemma catch (erro) {
      _relogio?.cancel();
      _fila = '';
      _mensagens.remove(resposta);
      _humor = Humor.confusa;
      if (mounted) avisar(context, '$erro', icone: Ic.wifiOff);
    }
    if (mounted) {
      setState(() {
        _respondendo = false;
        _falando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelo = context.watch<Ajustes>().modelo;
    final cor = context.watch<Sessao>().perfil.elemento.cor;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: CabecalhoAba('Conversa com o NAVI'),
        ),
        // A NAVI em 3D, mexendo a boca enquanto a resposta chega.
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              // Brilho na cor do elemento, atrás dela.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.2),
                      radius: 0.7,
                      colors: [cor.withValues(alpha: 0.16), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AvatarNavi(
                  enquadramento: Enquadramento.busto,
                  humor: _humor,
                  falando: _falando,
                ),
              ),
              // O busto some aos poucos em vez de terminar num corte reto.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 46,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Cores.fundo.withValues(alpha: 0), Cores.fundo],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 4,
                child: Pilula(
                  modelo,
                  icone: Ic.chip,
                  cor: Cores.verde,
                  fundo: Cores.verdeFundo,
                  borda: null,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _rolagem,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: _mensagens.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = _mensagens[i];
              if (!m.daNavi) return BalaoUsuario(m.texto);
              return BalaoNavi(m.texto.isEmpty ? '...' : m.texto);
            },
          ),
        ),
        if (_respondendo && _mensagens.last.texto.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${context.watch<Sessao>().perfil.nome} está pensando...',
              style: Estilos.legenda,
            ),
          ),
        CampoMensagem(
          controle: _campo,
          habilitado: !_respondendo,
          aoEnviar: _enviar,
        ),
      ],
    );
  }
}
