import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/services/api_codice.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';

/// Registro, login JWT e consulta protegida dos NAVIs (atividade de
/// comunicação segura). Veja COMUNICACAO_SEGURA.md.
class SessaoSeguraTela extends StatefulWidget {
  const SessaoSeguraTela({super.key, this.api, this.criarConta = false});

  /// Injetável nos testes; no app usa CODICE_API_URL.
  final ApiCodice? api;

  /// Abre no modo "criar conta" em vez de "entrar".
  final bool criarConta;

  @override
  State<SessaoSeguraTela> createState() => _SessaoSeguraTelaState();
}

class _SessaoSeguraTelaState extends State<SessaoSeguraTela> {
  late final Sessao _sessao = context.read<Sessao>();
  late final ApiCodice _api = widget.api ?? _sessao.api;
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _form = GlobalKey<FormState>();
  late bool _criandoConta = widget.criarConta;

  /// "manter conectado": guarda o token e abre direto na Home depois.
  bool _manter = true;
  List<NaviDaApi>? _navis;
  String? _aviso;
  String? _erro;
  bool _ocupado = false;
  bool _consultando = false;
  bool _limpezaPendente = false;

  @override
  void initState() {
    super.initState();
    // Reabriu o app: tenta recuperar a sessão guardada e confere na API.
    _executar(() async {
      if (await _api.lerToken() == null || !mounted) return;
      _aviso = 'Sessão recuperada do armazenamento seguro.';
      await _consultar();
    });
  }

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao();
    } on SessaoExpirada catch (falha) {
      await _sair(falha.mensagem);
    } on FalhaApi catch (falha) {
      if (mounted) _erro = falha.mensagem;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _sair(String mensagem) async {
    if (!mounted) return;
    _consultando = false;
    _criandoConta = false; // quem sai (ou expira) já tem conta: volta a "Entrar"
    _navis = null;
    _aviso = null;
    _limpezaPendente = true;
    _erro = mensagem;
    try {
      await _sessao.sair();
      if (mounted) _limpezaPendente = false;
    } on FalhaApi catch (falha) {
      if (mounted) _erro = '$mensagem ${falha.mensagem}';
    }
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final senha = _senha.text;
    // A senha não fica na tela nem na memória do campo.
    _senha.clear();
    _confirmacao.clear();
    final usuario = _usuario.text.trim();
    await _executar(() async {
      if (_criandoConta) {
        await _api.registrar(usuario, senha, manter: _manter);
      } else {
        await _api.entrar(usuario, senha, manter: _manter);
      }
      await _sessao.aoEntrar(manter: _manter);
      if (!mounted) return;
      _aviso = _criandoConta
          ? 'Conta criada. Sessão guardada com segurança.'
          : 'Login realizado. Sessão guardada com segurança.';
      await _consultar();
    });
  }

  Future<void> _consultar() async {
    if (!mounted) return;
    setState(() {
      _consultando = true;
      _navis = null;
    });
    final navis = await _api.consultar();
    if (mounted) _navis = navis;
  }

  /// Conta nova (ou sem NAVI ainda): primeiro cria a personalidade.
  void _irParaOCodice() => _sessao.temNavi
      ? Navigator.of(context).pushReplacementNamed(Rotas.app)
      : Navigator.of(context).pushReplacementNamed(Rotas.perfil, arguments: true);

  /// "entrar sem conta" não usa a API.
  void _entrarSemConta() => Navigator.of(context).pushReplacementNamed(Rotas.app);

  String? _obrigatorio(String? valor) =>
      valor == null || valor.trim().isEmpty ? 'Preencha este campo.' : null;

  // As mesmas regras da API, para avisar antes de enviar.
  String? _validarUsuario(String? valor) {
    final vazio = _obrigatorio(valor);
    if (vazio != null || !_criandoConta) return vazio;
    return RegExp(r'^[a-zA-Z0-9_.-]{3,32}$').hasMatch(valor!.trim())
        ? null
        : 'De 3 a 32 letras, números, ponto, hífen ou sublinhado.';
  }

  String? _validarSenha(String? valor) {
    final vazio = _obrigatorio(valor);
    if (vazio != null || !_criandoConta) return vazio;
    return valor!.length < 8 ? 'Use pelo menos 8 caracteres.' : null;
  }

  String? _validarConfirmacao(String? valor) =>
      valor == _senha.text ? null : 'As senhas não são iguais.';

  void _trocarModo() => setState(() {
    _criandoConta = !_criandoConta;
    _erro = null;
    _form.currentState?.reset();
  });

  @override
  Widget build(BuildContext context) {
    final navis = _navis;
    return PopScope(
      canPop: !_ocupado,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _consultando
                ? 'Consulta de NAVIs'
                : _criandoConta
                ? 'Criar conta'
                : 'Entrar no Códice',
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              _Cabecalho(
                icone: _consultando
                    ? Icons.verified_user_outlined
                    : _criandoConta
                    ? Icons.person_add_alt_1_outlined
                    : Icons.lock_outline,
                titulo: _consultando
                    ? 'Sessão protegida'
                    : _criandoConta
                    ? 'Sua conta do Códice'
                    : 'Bem-vindo de volta',
                texto: _consultando
                    ? 'o token JWT fica no armazenamento seguro do aparelho.'
                    : _criandoConta
                    ? 'seu NAVI fica guardado nela, em qualquer aparelho.'
                    : 'entre para encontrar o seu NAVI.',
              ),
              const SizedBox(height: 22),
              if (_aviso != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Cores.verde),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_aviso!, style: Estilos.corpo)),
                    ],
                  ),
                ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_ocupado)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: LinearProgressIndicator(),
                )
              else if (_limpezaPendente)
                FilledButton(
                  onPressed: () => _executar(() => _sair('Entre novamente.')),
                  child: const Text('Tentar apagar a sessão'),
                )
              else if (_consultando) ...[
                if (navis != null) ...[
                  if (navis.isEmpty)
                    const ListTile(title: Text('Nenhum NAVI cadastrado.')),
                  for (final navi in navis)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Cores.painel,
                        borderRadius: BorderRadius.circular(Estilos.raio),
                        border: Border.all(color: Cores.borda),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Cores.roxoFundo,
                            child: Text(
                              '${navi.id}',
                              style: const TextStyle(
                                color: Cores.roxoClaro,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(navi.nome, style: Estilos.tituloDialogo),
                                Text(
                                  'ID: ${navi.id} · ${navi.descricao}',
                                  style: Estilos.legenda,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _irParaOCodice,
                    child: const Text('Ir para o Códice'),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _executar(_consultar),
                  child: Text(
                    navis == null ? 'Tentar novamente' : 'Atualizar lista',
                  ),
                ),
                TextButton(
                  onPressed: () => _executar(() => _sair('Sessão encerrada.')),
                  child: const Text('Sair da sessão'),
                ),
              ] else
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usuario,
                        decoration: const InputDecoration(labelText: 'Usuário'),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: _validarUsuario,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _senha,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: _criandoConta
                            ? TextInputAction.next
                            : TextInputAction.done,
                        validator: _validarSenha,
                        onFieldSubmitted: (_) {
                          if (!_criandoConta) _entrar();
                        },
                      ),
                      if (_criandoConta) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmacao,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar senha',
                          ),
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          validator: _validarConfirmacao,
                          onFieldSubmitted: (_) => _entrar(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _manter,
                        onChanged: (v) => setState(() => _manter = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: const Text('manter conectado'),
                        subtitle: const Text(
                          'abre direto no seu NAVI da próxima vez',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _entrar,
                        child: Text(_criandoConta ? 'Criar conta' : 'Entrar'),
                      ),
                      TextButton(
                        onPressed: _trocarModo,
                        child: Text(
                          _criandoConta
                              ? 'já tenho conta, entrar'
                              : 'não tenho conta, criar uma',
                        ),
                      ),
                      // O resto do app funciona sem a API (ex.: fora do ar).
                      TextButton(
                        onPressed: _entrarSemConta,
                        child: const Text('entrar sem conta'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  const _Cabecalho({required this.icone, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Cores.roxoFundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Cores.roxoBorda),
          ),
          child: Icon(icone, color: Cores.roxoClaro, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Estilos.tituloDialogo),
              const SizedBox(height: 2),
              Text(texto, style: Estilos.legenda),
            ],
          ),
        ),
      ],
    );
  }
}
