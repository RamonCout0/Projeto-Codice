

class Memoria {
  final String texto;
  final Set<String> etiquetas;
  final DateTime quando;

  Memoria(this.texto, this.etiquetas, this.quando);
}

/// Como a Frost está reagindo agora. Cada evento empurra um humor, e o
/// humor decide a cor da borda e o ícone do balão — o feedback visual.
enum Humor { esperando, lendo, curiosa, feliz, confusa, pensando }
