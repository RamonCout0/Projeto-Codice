import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/estado_codice.dart';
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

  @override
  void dispose() {
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
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

    final ajustes = context.read<Ajustes>();
    final gemma = ConversaGemma(
      endereco: ajustes.enderecoOllama,
      modelo: ajustes.modelo,
    );
    final instrucoes = ConversaGemma.instrucoes(
      'Frost',
      context.read<EstadoCodice>().memorias,
    );
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

    try {
      await for (final pedaco in gemma.responder(instrucoes, historico)) {
        if (!mounted) return;
        setState(() {
          resposta.texto += pedaco;
          _falando = true;
          _humor = Humor.esperando;
        });
        _rolarParaOFim();
      }
      resposta.texto = resposta.texto.trim();
      _humor = resposta.texto.endsWith('?') ? Humor.curiosa : Humor.feliz;
    } on ErroGemma catch (erro) {
      _mensagens.remove(resposta);
      _humor = Humor.confusa;
      if (mounted) avisar(context, '$erro', icone: Icons.wifi_off);
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
              Positioned.fill(
                child: AvatarNavi(
                  enquadramento: Enquadramento.busto,
                  humor: _humor,
                  falando: _falando,
                ),
              ),
              Positioned(
                right: 12,
                top: 4,
                child: Pilula(
                  modelo,
                  icone: Icons.memory,
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
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('a Frost está pensando...', style: Estilos.legenda),
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
