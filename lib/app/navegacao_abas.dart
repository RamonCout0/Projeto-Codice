import 'package:flutter/foundation.dart';

/// Qual aba está aberta. Fica num lugar só para qualquer tela (os atalhos
/// da Home, por exemplo) poder levar a pessoa a outra aba.
class NavegacaoAbas extends ChangeNotifier {
  int _aba = 0;
  int get aba => _aba;

  void irPara(int indice) {
    if (indice == _aba) return;
    _aba = indice;
    notifyListeners();
  }
}
