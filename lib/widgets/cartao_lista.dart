import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';

class CartaoLista extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const CartaoLista({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.corIcone = Cores.roxo,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icone, color: corIcone),
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right, color: Cores.textoApagado),
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
          color: Cores.roxoFundo,
          shape: BoxShape.circle,
          border: Border.all(color: cor),
        ),
        child: Icon(icone, color: cor, size: 44),
      ),
    );
  }
}
