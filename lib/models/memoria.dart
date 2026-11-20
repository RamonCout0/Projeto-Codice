class Memoria {
  final String texto;
  final Set<String> etiquetas;
  final DateTime quando;

  Memoria(this.texto, this.etiquetas, this.quando);

  Map<String, Object> toJson() => {
    'texto': texto,
    'etiquetas': etiquetas.toList(),
    'quando': quando.toIso8601String(),
  };

  /// Null se o registro guardado estiver incompleto ou corrompido.
  static Memoria? fromJson(Object? dados) {
    if (dados is Map &&
        dados['texto'] is String &&
        dados['etiquetas'] is List &&
        dados['quando'] is String) {
      final quando = DateTime.tryParse(dados['quando'] as String);
      if (quando == null) return null;
      return Memoria(dados['texto'] as String, {
        for (final e in dados['etiquetas'] as List) e.toString(),
      }, quando);
    }
    return null;
  }
}
