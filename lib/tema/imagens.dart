import 'package:flutter/material.dart';

/// Imagens estáticas da Frost. Só o [AvatarNavi] usa estes arquivos:
/// quando o modelo VRM entrar, é lá que a troca acontece.
abstract final class Imagens {
  static const frostCorpo = AssetImage('assets/navis/frost.jpg');
  static const frostRosto = AssetImage('assets/navis/frost_rosto.jpg');
}
