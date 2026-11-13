import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';

/// Caixa com fundo e borda: a base visual de quase todos os cartões.
class Painel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color cor;
  final Color borda;
  final BorderRadius? raio;
  final double? altura;
  final EdgeInsetsGeometry? margem;

  const Painel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.cor = Cores.cartao,
    this.borda = Cores.borda,
    this.raio,
    this.altura,
    this.margem,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: altura,
      margin: margem,
      padding: padding,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: raio ?? BorderRadius.circular(Estilos.raio),
        border: Border.all(color: borda),
      ),
      child: child,
    );
  }
}

/// Selo pequeno com ícone opcional ("ficha", "off-line", "3 memórias").
class Pilula extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final Color cor;
  final Color fundo;
  final Color? borda;
  final VoidCallback? onTap;

  const Pilula(
    this.texto, {
    super.key,
    this.icone,
    this.cor = Cores.roxo,
    this.fundo = Cores.roxoFundo,
    this.borda = Cores.roxoBorda,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(15);
    return InkWell(
      onTap: onTap,
      borderRadius: raio,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: raio,
          border: borda == null ? null : Border.all(color: borda!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, color: cor, size: 13),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarraProgresso extends StatelessWidget {
  final double valor;
  final Color? cor;
  final double altura;

  const BarraProgresso(this.valor, {super.key, this.cor, this.altura = 5});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: altura,
        color: cor,
      ),
    );
  }
}

/// SnackBar única: esconde a anterior para os avisos não formarem fila.
void avisar(
  BuildContext context,
  String mensagem, {
  IconData icone = Icons.info_outline,
  SnackBarAction? acao,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: acao,
        content: Row(
          children: [
            Icon(icone, color: Cores.roxo, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(mensagem)),
          ],
        ),
      ),
    );
}
