import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onde ficam os segredos (token de login, chave da identidade, chave de
/// administrador). No celular é o armazenamento seguro do sistema (Keystore,
/// Keychain). O navegador não tem cofre de verdade: o plugin guarda no
/// localStorage e, em páginas HTTP (o app web servido pelo Tailscale), nem
/// funciona (o WebCrypto só existe em HTTPS), devolvendo vazio sem avisar.
/// Por isso, na web, o localStorage é usado direto e sem disfarce.
class Cofre {
  const Cofre([this._seguro = const FlutterSecureStorage()]);

  final FlutterSecureStorage _seguro;

  static String _chave(String key) => 'cofre.$key';

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      return (await SharedPreferences.getInstance()).getString(_chave(key));
    }
    return _seguro.read(key: key);
  }

  Future<void> write({required String key, required String? value}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_chave(key));
      } else {
        await prefs.setString(_chave(key), value);
      }
      return;
    }
    await _seguro.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).remove(_chave(key));
      return;
    }
    await _seguro.delete(key: key);
  }
}
