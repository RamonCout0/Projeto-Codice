import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:codice_app/services/cofre.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart';

/// Quem está usando o app e qual é o NAVI dessa pessoa.
///
/// - Com conta: o perfil do NAVI fica na API, e "manter conectado" guarda
///   o token e uma cópia do perfil no armazenamento seguro. Na próxima
///   abertura o app vai direto para a Home.
/// - Sem conta: o perfil fica só no aparelho.
class Sessao extends ChangeNotifier {
  Sessao({
    ApiCodice? api,
    Cofre storage = const Cofre(),
  }) : api = api ?? ApiCodice(enderecoApiCodice),
       _storage = storage;

  final ApiCodice api;
  final Cofre _storage;
  static const _chavePerfil = 'codice.perfil';

  PerfilNavi _perfil = PerfilNavi.padrao;
  bool _temNavi = false;
  String? _usuario;
  bool _conectado = false;
  bool _manter = false;
  bool _restaurando = true;

  PerfilNavi get perfil => _perfil;

  /// A pessoa já criou (ou personalizou) o próprio NAVI.
  bool get temNavi => _temNavi;
  String? get usuario => _usuario;
  bool get conectado => _conectado;
  bool get restaurando => _restaurando;

  /// Termina quando a sessão guardada foi conferida. true = pode ir direto
  /// para a Home.
  late final Future<bool> restaurada = _restaurar();

  Future<bool> _restaurar() async {
    try {
      await _lerCopia();
      final token = await api.lerToken();
      if (token == null || token.isEmpty) return false;
      _conectado = true;
      _manter = true; // só há token gravado quando a pessoa pediu
      try {
        await _buscarPerfil();
      } on SessaoExpirada {
        await sair();
        return false;
      } on FalhaApi {
        // API fora do ar: segue com a cópia do perfil guardada no aparelho.
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _restaurando = false;
      notifyListeners();
    }
  }

  /// Depois de entrar ou criar a conta na API.
  Future<void> aoEntrar({required bool manter}) async {
    _conectado = true;
    _manter = manter;
    if (!manter) await _apagarCopia();
    await _buscarPerfil();
  }

  Future<void> _buscarPerfil() async {
    final resposta = await api.lerPerfil();
    _usuario = resposta.usuario;
    final navi = resposta.navi;
    if (navi != null) {
      _perfil = navi;
      _temNavi = true;
      await _guardarCopia();
    } else {
      _temNavi = false;
    }
    notifyListeners();
  }

  /// Salva o NAVI: na conta, se houver, e no aparelho quando permitido.
  Future<void> salvarPerfil(PerfilNavi perfil) async {
    if (_conectado) {
      final resposta = await api.salvarPerfil(perfil);
      _usuario = resposta.usuario;
    }
    _perfil = perfil;
    _temNavi = true;
    await _guardarCopia();
    notifyListeners();
  }

  /// Sai da conta e esquece o NAVI dela neste aparelho.
  Future<void> sair() async {
    _conectado = false;
    _manter = false;
    _usuario = null;
    _perfil = PerfilNavi.padrao;
    _temNavi = false;
    notifyListeners();
    await _apagarCopia();
    await api.apagarSessao();
  }

  // Sem conta, a cópia é o único lugar do perfil. Com conta, só quando a
  // pessoa pediu para manter a sessão.
  bool get _podeGuardar => !_conectado || _manter;

  Future<void> _guardarCopia() async {
    if (!_podeGuardar) return;
    try {
      await _storage.write(key: _chavePerfil, value: jsonEncode(_perfil.toJson()));
    } catch (_) {
      // Sem armazenamento (ex.: testes): o perfil vale até fechar o app.
    }
  }

  Future<void> _lerCopia() async {
    try {
      final texto = await _storage.read(key: _chavePerfil);
      final perfil = texto == null ? null : PerfilNavi.fromJson(jsonDecode(texto));
      if (perfil != null) {
        _perfil = perfil;
        _temNavi = true;
      }
    } catch (_) {
      // Cópia ausente ou corrompida: fica o NAVI padrão.
    }
  }

  Future<void> _apagarCopia() async {
    try {
      await _storage.delete(key: _chavePerfil);
    } catch (_) {}
  }
}
