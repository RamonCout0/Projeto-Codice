import 'dart:async';

import 'package:codice_app/widgets/navi_vetor.dart';

/// Roda antes de todos os testes desta pasta: sem a respiração da NAVI, o
/// pumpAndSettle dos testes de tela consegue terminar.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NaviVetor.animacoesAtivas = false;
  await testMain();
}
