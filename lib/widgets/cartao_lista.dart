import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/icones.dart';

/// Item de lista em cartão: ícone num quadrado tingido, título e detalhe.
class CartaoLista extends StatelessWidget {
  final Ic icone;
  final Color? corIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  /// Substitui o quadrado do ícone (ex.: o retrato de um NAVI).
  final Widget? lider;

  const CartaoLista({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.lider,
    this.corIcone,
  });

  @override
  Widget build(BuildContext context) {
    final destaque = corIcone ?? Cores.roxo;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: Efeitos.volume(Cores.cartao),
        borderRadius: BorderRadius.circular(Estilos.raio),
        border: Border.all(color: Cores.borda),
        boxShadow: Efeitos.sombraCartao,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(Estilos.raio),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              lider ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: destaque.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: destaque.withValues(alpha: 0.3)),
                ),
                child: IconeCodice(icone, color: destaque, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: Cores.texto,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitulo, style: Estilos.legenda),
                  ],
                ),
              ),
              if (onTap != null) IconeCodice(Ic.setaDir, color: Cores.textoApagado),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Cartão de resumo no topo das listas (Cidade, Encontros).
class CartaoDestaque extends StatelessWidget {
  final Ic icone;
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        gradient: Efeitos.tingido(cor, forca: 0.2),
        boxShadow: Efeitos.sombraCartao,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: Efeitos.brilho(cor, forca: 0.3, desfoque: 20),
            ),
            child: IconeCodice(icone, color: cor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Estilos.tituloDialogo),
                const SizedBox(height: 4),
                Text(texto, style: Estilos.legenda.copyWith(fontSize: 13, color: Cores.textoSecundario)),
                if (progresso != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progresso,
                      minHeight: 6,
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
  final Ic icone;
  final Color? cor;

  const IconeDestaque(this.icone, {super.key, this.cor});

  @override
  Widget build(BuildContext context) {
    final destaque = cor ?? Cores.roxo;
    return Center(
      child: Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: destaque.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: destaque.withValues(alpha: 0.7), width: 1.5),
          boxShadow: Efeitos.brilho(destaque, forca: 0.3, desfoque: 36),
        ),
        child: Center(child: IconeCodice(icone, color: destaque, size: 46)),
      ),
    );
  }
}
