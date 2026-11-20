import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/views/diario/pagina_diario.dart';
import 'package:codice_app/widgets/icones.dart';

/// Rodapé fixo, fora da rolagem: guardar e apagar sempre à mão.
class RodapeDiario extends StatelessWidget {
  final int faltam;
  final bool processando;

  /// null deixa o botão desabilitado: a regra aparece no próprio botão.
  final VoidCallback? aoGuardar;
  final VoidCallback aoTocarApagar;
  final VoidCallback aoSegurarApagar;

  const RodapeDiario({
    super.key,
    required this.faltam,
    required this.processando,
    required this.aoGuardar,
    required this.aoTocarApagar,
    required this.aoSegurarApagar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: aoGuardar,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: processando
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('guardando...'),
                      ],
                    )
                  : Text(
                      faltam > 0
                          ? 'escreva mais ${plural(faltam, 'palavra')}'
                          : 'guardar no diário',
                    ),
            ),
          ),
          const SizedBox(width: 9),
          // Apagar é destrutivo: o toque só explica, segurar apaga.
          OutlinedButton(
            onPressed: processando ? null : aoTocarApagar,
            onLongPress: processando ? null : aoSegurarApagar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(48),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              backgroundColor: Cores.roxoFundo,
              foregroundColor: Cores.roxo,
              side: BorderSide(color: Cores.bordaRoxa),
            ),
            child: const IconeCodice(Ic.apagar, size: 20),
          ),
        ],
      ),
    );
  }
}
