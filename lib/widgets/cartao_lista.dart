import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';

/// Item de lista em cartão: ícone num quadrado tingido, título e detalhe.
class CartaoLista extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  const CartaoLista({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.corIcone = Cores.roxo,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Estilos.raio),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corIcone.withValues(alpha: 0.3)),
                ),
                child: Icon(icone, color: corIcone, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: Estilos.legenda),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Cores.textoApagado),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão de resumo no topo das listas (Cidade, Encontros).
class CartaoDestaque extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;

  /// 0 a 1; null esconde a barra.
  final double? progresso;

  const CartaoDestaque({
    super.key,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
    this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor.withValues(alpha: 0.16), Cores.cartao],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.25), blurRadius: 18)],
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Estilos.tituloDialogo),
                const SizedBox(height: 3),
                Text(texto, style: Estilos.legenda.copyWith(color: Cores.textoSecundario)),
                if (progresso != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progresso,
                      minHeight: 5,
                      color: cor,
                      backgroundColor: Cores.trilho,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícone grande em círculo, usado no topo das telas de detalhe.
class IconeDestaque extends StatelessWidget {
  final IconData icone;
  final Color cor;

  const IconeDestaque(this.icone, {super.key, this.cor = Cores.roxo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: cor.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(color: cor.withValues(alpha: 0.25), blurRadius: 30),
          ],
        ),
        child: Icon(icone, color: cor, size: 44),
      ),
    );
  }
}
