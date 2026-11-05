import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/codice_app.dart';
import 'package:codice_app/controllers/estado_codice.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => EstadoCodice(),
      child: const CodiceApp(),
    ),
  );
}
