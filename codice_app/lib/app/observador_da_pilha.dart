import 'package:flutter/material.dart';

class ObservadorDaPilha extends NavigatorObserver {
  final String nome;
  final List<Route<dynamic>> _rotas = [];

  ObservadorDaPilha(this.nome);

  String _nomeDe(Route<dynamic> r) =>
      r.settings.name ?? (r is PopupRoute ? '(diálogo)' : '(sem nome)');

  /// Ex.: "/encontros > /encontros/navi"
  String get pilha => _rotas.map(_nomeDe).join(' > ');

  int get tamanho => _rotas.length;

  void _log(String operacao, Route<dynamic> r) {
    debugPrint('[pilha $nome] $operacao ${_nomeDe(r)}  =>  [$pilha]');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.add(route);
    _log('PUSH', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.remove(route);
    _log('POP ', route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.remove(route);
    _log('REMOVE', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _rotas.indexOf(oldRoute);
    if (newRoute == null) return;
    if (i >= 0) {
      _rotas[i] = newRoute;
    } else {
      _rotas.add(newRoute);
    }
    _log('REPLACE ${oldRoute == null ? '' : _nomeDe(oldRoute)} ->',
        newRoute);
  }
}
