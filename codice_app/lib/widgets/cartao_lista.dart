import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';

class CartaoLista extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const CartaoLista({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.corIcone = kPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1924),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Color(0xFF302D3B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icone, color: corIcone),
        title: Text(
          titulo,
          style: const TextStyle(color: Color(0xFFE4E0E9), fontSize: 13),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(color: Color(0xFF8B8498), fontSize: 10),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8B8498)),
      ),
    );
  }
}
