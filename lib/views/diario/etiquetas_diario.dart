import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/icones.dart';

/// Etiquetas sugeridas pela leitura do texto. Tocar alterna entre
/// aceita e recusada; o "+" cria uma etiqueta à mão.
class EtiquetasDiario extends StatelessWidget {
  final List<String> nomes;
  final Set<String> ativas;
  final bool travadas;
  final ValueChanged<String> aoAlternar;
  final VoidCallback aoCriar;

  const EtiquetasDiario({
    super.key,
    required this.nomes,
    required this.ativas,
    required this.travadas,
    required this.aoAlternar,
    required this.aoCriar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ETIQUETAS SUGERIDAS', style: Estilos.secao),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (nomes.isEmpty)
              Text(
                'aparecem enquanto você escreve',
                style: TextStyle(color: Cores.textoFraco, fontSize: 12),
              ),
            for (final nome in nomes)
              _Etiqueta(
                nome: nome,
                ativa: ativas.contains(nome),
                onTap: travadas ? null : () => aoAlternar(nome),
              ),
            IconButton.outlined(
              tooltip: 'nova etiqueta',
              onPressed: travadas ? null : aoCriar,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Cores.roxoFundo,
                foregroundColor: Cores.roxo,
                side: BorderSide(color: Cores.bordaRoxa),
              ),
              icon: const IconeCodice(Ic.mais),
            ),
          ],
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback? onTap;

  const _Etiqueta({required this.nome, required this.ativa, this.onTap});

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(14);
    final cor = ativa ? Cores.roxoClaro : Cores.textoFraco;
    return InkWell(
      onTap: onTap,
      borderRadius: raio,
      child: Ink(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ativa ? Cores.roxoAtivo : Cores.cartaoClaro,
          borderRadius: raio,
          border: Border.all(
            color: ativa ? Cores.roxo : Cores.bordaForte,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconeCodice(
              ativa ? Ic.check : Ic.fechar,
              size: 12,
              color: ativa ? Cores.roxo : Cores.textoFraco,
            ),
            const SizedBox(width: 4),
            Text(
              nome,
              style: TextStyle(
                color: cor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: ativa ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
