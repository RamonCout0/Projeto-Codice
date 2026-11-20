import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codice_app/models/memoria.dart';

/// Uma pergunta que a NAVI ainda quer fazer: duas memórias se contradizem.
class PerguntaPendente {
  const PerguntaPendente(this.antiga, this.etiqueta);

  /// A memória antiga, que pode ser trocada pela nova.
  final Memoria antiga;
  final String etiqueta;

  String get texto =>
      etiqueta == 'emprego' ? 'Você mudou de emprego?' : 'Isso mudou?';
}

/// O que a NAVI sabe: escrito no Diário e usado na Conversa. As memórias
/// ficam guardadas no aparelho, e a idade da NAVI cresce com elas (como diz
/// a ideia do projeto: a idade é o conhecimento adquirido pela convivência).
class EstadoCodice extends ChangeNotifier {
  static const _chave = 'codice.memorias';

  /// A cada quantas memórias a NAVI faz aniversário.
  static const memoriasPorAno = 5;
  static const idadeInicial = 8;
  static const idadeMaxima = 18;

  final List<Memoria> _memorias = [];
  PerguntaPendente? _pergunta;

  List<Memoria> get memorias => List.unmodifiable(_memorias);
  PerguntaPendente? get pergunta => _pergunta;

  int get idade =>
      math.min(idadeMaxima, idadeInicial + _memorias.length ~/ memoriasPorAno);

  String get fase => idade < 14
      ? 'criança'
      : idade < idadeMaxima
      ? 'adolescente'
      : 'adulta';

  /// 0 a 1: quanto falta para o próximo aniversário.
  double get progressoIdade =>
      idade >= idadeMaxima ? 1 : (_memorias.length % memoriasPorAno) / memoriasPorAno;

  int get faltamParaCrescer =>
      idade >= idadeMaxima ? 0 : memoriasPorAno - (_memorias.length % memoriasPorAno);

  /// Lê as memórias guardadas no aparelho.
  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      final texto = prefs.getString(_chave);
      if (texto == null) return;
      final dados = jsonDecode(texto);
      if (dados is! List) return;
      _memorias
        ..clear()
        ..addAll(dados.map(Memoria.fromJson).whereType<Memoria>());
      notifyListeners();
    } catch (_) {
      // Sem armazenamento (testes) ou dado corrompido: começa vazio.
    }
  }

  Future<void> _salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      await prefs.setString(
        _chave,
        jsonEncode([for (final m in _memorias) m.toJson()]),
      );
    } catch (_) {
      // Sem armazenamento: as memórias valem até fechar o app.
    }
  }

  void guardarMemoria(Memoria memoria) {
    _memorias.insert(0, memoria);
    notifyListeners();
    _salvar();
  }

  void esquecerMemoria(Memoria memoria) {
    if (_memorias.remove(memoria)) {
      if (_pergunta?.antiga == memoria) _pergunta = null;
      notifyListeners();
      _salvar();
    }
  }

  void perguntar(PerguntaPendente pergunta) {
    _pergunta = pergunta;
    notifyListeners();
  }

  void encerrarPergunta() {
    if (_pergunta == null) return;
    _pergunta = null;
    notifyListeners();
  }
}
