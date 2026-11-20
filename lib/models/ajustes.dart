import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Aparência do app: segue o aparelho, ou fixa o tema claro ou o noturno.
enum ModoTema { sistema, claro, escuro }

/// Preferências do app, guardadas em ajustes.json na pasta do aparelho.
class Ajustes extends ChangeNotifier {
  /// Endereço do Ollama no PC. Dá para fixar na hora de rodar:
  /// flutter run --dart-define=OLLAMA_URL=http://192.168.0.10:11434
  /// Sem isso: na web o Ollama está no próprio PC (localhost); no Android,
  /// 10.0.2.2 é o PC visto de dentro do emulador.
  static const _enderecoFixo = String.fromEnvironment('OLLAMA_URL');
  static final enderecoPadrao = _enderecoFixo.isNotEmpty
      ? _enderecoFixo
      : kIsWeb
      ? 'http://localhost:11434'
      : 'http://10.0.2.2:11434';
  static const modeloPadrao = 'gemma3:1b';

  String enderecoOllama = enderecoPadrao;
  String modelo = modeloPadrao;

  /// O noturno é a cara do app, então é o padrão.
  ModoTema modoTema = ModoTema.escuro;

  File? _arquivo;

  Future<void> carregar() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _arquivo = File('${docs.path}/ajustes.json');
      if (!await _arquivo!.exists()) return;
      final j =
          jsonDecode(await _arquivo!.readAsString()) as Map<String, dynamic>;
      enderecoOllama = j['enderecoOllama'] as String? ?? enderecoOllama;
      modelo = j['modelo'] as String? ?? modelo;
      modoTema = ModoTema.values.where((m) => m.name == j['modoTema']).firstOrNull ?? modoTema;
      notifyListeners();
    } catch (_) {
      // Sem pasta (testes) ou arquivo corrompido: fica com o padrão.
    }
  }

  /// Altera e salva: `ajustes.alterar(() => ajustes.modelo = 'x')`.
  Future<void> alterar(VoidCallback mudanca) async {
    mudanca();
    notifyListeners();
    await _arquivo?.writeAsString(
      jsonEncode({
        'enderecoOllama': enderecoOllama,
        'modelo': modelo,
        'modoTema': modoTema.name,
      }),
    );
  }
}
