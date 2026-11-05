

class LeituraDiario {
  static const Map<String, List<String>> pistas = {
    'prova': ['prova', 'exame', 'estud'],
    'sono': ['dormi', 'sono', 'olho', 'acordei', 'cansad'],
    'Bia': ['bia'],
    'emprego': ['emprego', 'trabalh'],
    'comida': ['almoç', 'almoc', 'jant', 'comid', 'comer'],
  };

  Set<String> detectar(String texto) {
    // Separa por qualquer coisa que não seja letra (inclui acentuadas).
    final palavras = texto
        .toLowerCase()
        .split(RegExp(r'[^a-zà-ÿ]+'))
        .where((p) => p.isNotEmpty);
    return {
      for (final pista in pistas.entries)
        if (palavras.any((w) => pista.value.any(w.startsWith))) pista.key,
    };
  }

  int contarPalavras(String valor) {
    final limpo = valor.trim();
    return limpo.isEmpty ? 0 : limpo.split(RegExp(r'\s+')).length;
  }
}
