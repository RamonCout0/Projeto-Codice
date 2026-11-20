import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codice_app/models/lugar.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart' show FalhaApi;
import 'package:codice_app/services/api_navicity.dart';
import 'package:codice_app/services/narracao.dart';

enum EstadoCidade { desconectada, conectando, conectada, erro }

/// A NAVICity vista pelo app: onde o NAVI está, os lugares, os fatos e os
/// NAVIs que ele conheceu. Tudo vem do servidor; nada é escrito à mão. Só os
/// apelidos que a pessoa dá ficam no aparelho.
class CidadeNavi extends ChangeNotifier {
  CidadeNavi({
    ApiNavicity Function(String conta)? fabrica,
    DateTime Function()? agora,
    this.intervalo = const Duration(seconds: 20),
  }) : _fabrica = fabrica ?? ((conta) => ApiNavicity(enderecoNavicity, conta: conta)),
       _agora = agora ?? DateTime.now;

  static const _chaveApelidos = 'cidade.apelidos';
  static const _tamanhoPagina = 200; // igual ao do servidor

  final ApiNavicity Function(String conta) _fabrica;
  final DateTime Function() _agora;
  final Duration intervalo;

  ApiNavicity? _api;
  String _conta = 'local';
  PerfilNavi? _perfil;
  Timer? _timer;
  bool _ocupado = false;

  EstadoCidade estado = EstadoCidade.desconectada;
  String? erro;
  SituacaoNaCidade? situacao;

  final List<FatoDaCidade> _fatos = [];
  int _cursor = 0;
  int _agoraSeg = 0;
  DateTime? _recebidoEm;
  Map<String, String> _apelidos = {};

  /// Nome do NAVI do usuário, usado nas frases.
  String get meuNome => _perfil?.nome ?? 'seu NAVI';

  List<FatoDaCidade> get fatos => List.unmodifiable(_fatos);

  /// Segundos da cidade agora: o relógio do último contato mais o tempo que
  /// passou aqui desde então.
  int get agoraSegundos {
    final desde = _recebidoEm == null
        ? 0
        : _agora().difference(_recebidoEm!).inSeconds;
    return _agoraSeg + desde;
  }

  String quando(int quandoSeg) => haQuanto(agoraSegundos - quandoSeg);

  List<Lugar> get lugares => [
    for (final a in situacao?.areas ?? const <AreaDaCidade>[]) Lugar.daArea(a),
  ];

  /// Fatos que aconteceram num lugar, do mais novo para o mais velho.
  List<FatoDaCidade> fatosDoLugar(String nome) => [
    for (final f in _fatos.reversed)
      if (f.area == nome) f,
  ];

  FatoDaCidade? get ultimoFato => _fatos.isEmpty ? null : _fatos.last;

  /// Fatos ligados a um NAVI específico (do mais novo para o mais velho).
  List<FatoDaCidade> fatosCom(String nome) => [
    for (final f in _fatos.reversed)
      if (f.outro == nome) f,
  ];

  /// Os NAVIs que o do usuário conheceu, do contato mais recente para o
  /// mais antigo. Quem só recusou conversa não entra.
  List<NaviEncontrado> get encontros {
    final por = <String, _Acumulo>{};
    for (final f in _fatos) {
      final nome = f.outro;
      if (nome == null || nome.isEmpty) continue;
      if (!const {'conheceu', 'conversou', 'recusou', 'mudou_tom'}.contains(f.tipo)) {
        continue;
      }
      final a = por.putIfAbsent(nome, () => _Acumulo(nome, f.outroGm));
      a.ultimo = f;
      if (f.afinidade != null) a.afinidade = f.afinidade!;
      if (f.tom != null && f.tom!.isNotEmpty) a.tom = f.tom!;
      if (f.tipo == 'conheceu' || f.tipo == 'conversou') a.encontros++;
    }
    final lista = [
      for (final a in por.values)
        if (a.encontros > 0)
          NaviEncontrado(
            nome: a.nome,
            gm: a.gm,
            afinidade: a.afinidade,
            encontros: a.encontros,
            tom: a.tom,
            quando: quando(a.ultimo!.quandoSegundos),
            ultimaArea: a.ultimo!.area,
            relato: narrar(a.ultimo!, meuNome),
            cor: corDoNavi(a.nome, a.gm),
            apelido: _apelidos[a.nome],
          ),
    ];
    final ordem = {for (final a in por.values) a.nome: a.ultimo!.seq};
    lista.sort((x, y) => (ordem[y.nome] ?? 0).compareTo(ordem[x.nome] ?? 0));
    return lista;
  }

  NaviEncontrado? encontro(String nome) {
    for (final n in encontros) {
      if (n.nome == nome) return n;
    }
    return null;
  }

  // ---------------------------------------------------------------- conexão

  /// Entra na cidade com o NAVI da conta (ou "local", sem conta). Repetir a
  /// chamada com a mesma conta e o mesmo NAVI não faz nada.
  Future<void> conectar(PerfilNavi perfil, {String conta = 'local'}) async {
    if (_ocupado) return;
    final mesmo = conta == _conta && perfil == _perfil && _api != null;
    if (mesmo && estado == EstadoCidade.conectada) return;
    if (!mesmo) {
      parar();
      _limpar();
      _api = _fabrica(conta);
    }
    _conta = conta;
    _perfil = perfil;
    await _carregarApelidos();
    _ocupado = true;
    estado = EstadoCidade.conectando;
    erro = null;
    notifyListeners();
    try {
      situacao = await _api!.entrar(perfil);
      _marcarRelogio(situacao!.agoraSegundos);
      await _buscarFatos();
      estado = EstadoCidade.conectada;
      _iniciar();
    } on FalhaApi catch (e) {
      estado = EstadoCidade.erro;
      erro = e.mensagem;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  /// Tenta conectar de novo depois de uma falha.
  Future<void> tentarDeNovo() async {
    final perfil = _perfil;
    if (perfil == null) return;
    await conectar(perfil, conta: _conta);
  }

  /// Pede o que mudou. Se a cidade reiniciou (o servidor ainda não guarda
  /// nada em disco), o NAVI entra de novo sozinho.
  Future<void> atualizar() async {
    final api = _api;
    if (_ocupado || api == null) return;
    _ocupado = true;
    try {
      try {
        final nova = await api.situacao();
        if (nova.agoraSegundos < _agoraSeg) _limpar(); // a cidade recomeçou
        situacao = nova;
        _marcarRelogio(nova.agoraSegundos);
      } on FalhaApi {
        final perfil = _perfil;
        if (perfil == null) rethrow;
        _limpar();
        situacao = await api.entrar(perfil);
        _marcarRelogio(situacao!.agoraSegundos);
      }
      await _buscarFatos();
      estado = EstadoCidade.conectada;
      erro = null;
    } on FalhaApi catch (e) {
      estado = EstadoCidade.erro;
      erro = e.mensagem;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> _buscarFatos() async {
    final api = _api!;
    while (true) {
      final r = await api.fatos(desde: _cursor);
      _fatos.addAll(r.fatos);
      _cursor = r.cursor;
      _marcarRelogio(r.agoraSegundos);
      if (r.fatos.length < _tamanhoPagina) break;
    }
  }

  void _marcarRelogio(int segundos) {
    _agoraSeg = segundos;
    _recebidoEm = _agora();
  }

  void _iniciar() {
    _timer?.cancel();
    _timer = Timer.periodic(intervalo, (_) => atualizar());
  }

  /// Para a atualização periódica (o app saiu da tela principal).
  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  void _limpar() {
    _fatos.clear();
    _cursor = 0;
    _agoraSeg = 0;
    _recebidoEm = null;
    situacao = null;
  }

  /// Esquece a cidade deste aparelho (ao sair da conta).
  void desconectar() {
    parar();
    _limpar();
    _api = null;
    _perfil = null;
    _conta = 'local';
    estado = EstadoCidade.desconectada;
    erro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    parar();
    super.dispose();
  }

  // --------------------------------------------------------------- apelidos

  Future<void> alterarApelido(String nome, String novo) async {
    final limpo = novo.trim();
    if (limpo.isEmpty) return;
    _apelidos = {..._apelidos, nome: limpo};
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_chaveApelidos.$_conta', jsonEncode(_apelidos));
    } catch (_) {
      // Sem armazenamento (ex.: testes): o apelido vale até fechar o app.
    }
  }

  Future<void> _carregarApelidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString('$_chaveApelidos.$_conta');
      if (texto == null) {
        _apelidos = {};
        return;
      }
      final dados = jsonDecode(texto);
      if (dados is Map) {
        _apelidos = {for (final e in dados.entries) '${e.key}': '${e.value}'};
      }
    } catch (_) {
      _apelidos = {};
    }
  }
}

class _Acumulo {
  _Acumulo(this.nome, this.gm);
  final String nome;
  final bool gm;
  FatoDaCidade? ultimo;
  int afinidade = 50;
  String tom = 'indiferente';
  int encontros = 0;
}

/// Cor estável de cada NAVI da cidade: a mesma sempre, sem guardar nada.
/// GMs usam a do elemento Cyber.
Color corDoNavi(String nome, bool gm) {
  if (gm) return Elemento.cyber.cor;
  final cores = Elemento.escolhiveis;
  var h = 0;
  for (final c in nome.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return cores[h % cores.length].cor;
}
