import 'package:flutter/material.dart';
import 'package:codice_app/models/lugar.dart';

const List<Lugar> lugares = [
  Lugar(
    'Praça dos Bipes',
    'Onde os NAVIs treinam Navidês no fim da tarde. A Frost costuma '
        'ficar no banco perto da fonte.',
    'revelado no primeiro dia',
    Icons.graphic_eq,
  ),
  Lugar(
    'Biblioteca Velha',
    'A Frost vem aqui reler o que você escreveu no diário. É o lugar '
        'mais silencioso da cidade.',
    'revelado ao guardar a primeira memória',
    Icons.local_library_outlined,
  ),
  Lugar(
    'Café da Esquina',
    'Apareceu no mapa quando você passou por um café de verdade. Tem '
        'sempre algum NAVI novo por lá.',
    'revelado pela sua localização',
    Icons.local_cafe_outlined,
  ),
];
