import 'package:flutter/material.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart' show FalhaApi;
import 'package:codice_app/services/api_gm.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/foto_navi.dart';
import 'package:codice_app/widgets/icones.dart';
import 'package:codice_app/models/humor.dart';

/// Configuração da Iris, a game master da cidade. Só quem tem a chave de
/// administrador do servidor consegue abrir: os traços mudam o jeito dela
/// agir na cidade na hora, e o texto de personalidade fica guardado para a
/// IA narrar.
class IrisConfigTela extends StatefulWidget {
  final ApiGm? api;

  const IrisConfigTela({super.key, this.api});

  @override
  State<IrisConfigTela> createState() => _IrisConfigTelaState();
}

class _IrisConfigTelaState extends State<IrisConfigTela> {
  late final ApiGm _api = widget.api ?? ApiGm();
  final _chave = TextEditingController();
  final _texto = TextEditingController();

  String? _chaveAtiva; // com ela a tela está destravada
  ConfigIris? _config;
  bool _ocupado = true;
  String? _erro;

  static const _rotulos = {
    'coragem': ('Coragem', 'topa ir a lugares novos e puxar conversa com estranhos'),
    'curiosidade': ('Curiosidade', 'se entedia no mesmo lugar e quer explorar a cidade'),
    'paciencia': ('Paciência', 'aguenta grosseria e demora para se magoar'),
    'sociabilidade': ('Sociabilidade', 'procura companhia e aceita conversas'),
    'agressividade': ('Agressividade', 'incomoda os outros e se irrita fácil'),
  };

  @override
  void initState() {
    super.initState();
    _tentarChaveGuardada();
  }

  @override
  void dispose() {
    _chave.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _tentarChaveGuardada() async {
    final guardada = await _api.chaveGuardada();
    if (guardada == null || guardada.isEmpty) {
      if (mounted) setState(() => _ocupado = false);
      return;
    }
    await _destravar(guardada, guardar: false);
  }

  Future<void> _destravar(String chave, {bool guardar = true}) async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final config = await _api.ler(chave);
      if (guardar) await _api.guardarChave(chave.trim());
      if (!mounted) return;
      _texto.text = config.personalidade;
      setState(() {
        _chaveAtiva = chave.trim();
        _config = config;
        _ocupado = false;
      });
    } on FalhaApi catch (e) {
      if (!mounted) return;
      // Uma chave guardada que deixou de valer é esquecida.
      if (!guardar) await _api.esquecerChave();
      setState(() {
        _erro = guardar ? e.mensagem : null;
        _ocupado = false;
      });
    }
  }

  Future<void> _salvar() async {
    final chave = _chaveAtiva;
    final config = _config;
    if (chave == null || config == null) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final salva = await _api.salvar(chave, config.copiar(personalidade: _texto.text.trim()));
      if (!mounted) return;
      setState(() {
        _config = salva;
        _ocupado = false;
      });
      avisar(context, 'A Iris já está agindo assim na cidade.', icone: Ic.checkCirculo);
    } on FalhaApi catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _ocupado = false;
      });
    }
  }

  Future<void> _trancar() async {
    await _api.esquecerChave();
    if (!mounted) return;
    setState(() {
      _chaveAtiva = null;
      _config = null;
      _chave.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cyber = Elemento.cyber.cor;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const CabecalhoDetalhe('Iris · GM'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  FotoNavi(cor: cyber, gm: true, tamanho: 84, redonda: true, humor: Humor.curiosa),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Iris', style: Estilos.titulo),
                        const SizedBox(height: 6),
                        Pilula(
                          'Cyber · game master',
                          icone: Ic.gm,
                          cor: cyber,
                          fundo: cyber.withValues(alpha: 0.12),
                          borda: cyber.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ocupado && _config == null
                  ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                  : _config == null
                  ? _Trancada(controle: _chave, erro: _erro, aoEntrar: () => _destravar(_chave.text))
                  : _Editor(
                      config: _config!,
                      texto: _texto,
                      ocupado: _ocupado,
                      erro: _erro,
                      rotulos: _rotulos,
                      aoMudar: (c) => setState(() => _config = c),
                      aoSalvar: _salvar,
                      aoTrancar: _trancar,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Trancada extends StatelessWidget {
  final TextEditingController controle;
  final String? erro;
  final VoidCallback aoEntrar;

  const _Trancada({required this.controle, required this.erro, required this.aoEntrar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Painel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeCodice(Ic.cadeado, color: Cores.ambar, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Só o dono da cidade configura a Iris. Digite a chave de '
                  'administrador do servidor (fica guardada só neste aparelho).',
                  style: Estilos.corpoSuave,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controle,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'chave de administrador'),
          onSubmitted: (_) => aoEntrar(),
        ),
        if (erro != null) ...[
          const SizedBox(height: 10),
          Text(erro!, style: TextStyle(color: Cores.vermelho, fontSize: 13)),
        ],
        const SizedBox(height: 14),
        ElevatedButton(onPressed: aoEntrar, child: const Text('entrar')),
      ],
    );
  }
}

class _Editor extends StatelessWidget {
  final ConfigIris config;
  final TextEditingController texto;
  final bool ocupado;
  final String? erro;
  final Map<String, (String, String)> rotulos;
  final ValueChanged<ConfigIris> aoMudar;
  final VoidCallback aoSalvar;
  final VoidCallback aoTrancar;

  const _Editor({
    required this.config,
    required this.texto,
    required this.ocupado,
    required this.erro,
    required this.rotulos,
    required this.aoMudar,
    required this.aoSalvar,
    required this.aoTrancar,
  });

  @override
  Widget build(BuildContext context) {
    final cyber = Elemento.cyber.cor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('COMPORTAMENTO', style: Estilos.secao),
        const SizedBox(height: 4),
        Text(
          'Mudam o jeito dela agir na cidade assim que você salvar.',
          style: Estilos.legenda,
        ),
        const SizedBox(height: 10),
        for (final c in ConfigIris.chaves)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rotulos[c]!.$1, style: Estilos.corpo.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${config.tracos[c]}', style: TextStyle(color: cyber, fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: config.tracos[c]!.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: cyber,
                  onChanged: ocupado
                      ? null
                      : (v) => aoMudar(config.copiar(tracos: {...config.tracos, c: v.round()})),
                ),
                Text(rotulos[c]!.$2, style: Estilos.legenda),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text('PERSONALIDADE', style: Estilos.secao),
        const SizedBox(height: 4),
        Text(
          'Texto livre para a IA da Iris narrar a cidade no jeito dela.',
          style: Estilos.legenda,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: texto,
          maxLines: 7,
          minLines: 4,
          maxLength: ConfigIris.maxPersonalidade,
          decoration: const InputDecoration(hintText: 'Como a Iris pensa, fala e age...'),
        ),
        if (erro != null) ...[
          const SizedBox(height: 4),
          Text(erro!, style: TextStyle(color: Cores.vermelho, fontSize: 13)),
        ],
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: ocupado ? null : aoSalvar,
          icon: IconeCodice(Ic.check, size: 18),
          label: Text(ocupado ? 'salvando…' : 'salvar'),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: aoTrancar, child: const Text('trancar (esquecer a chave)')),
      ],
    );
  }
}
