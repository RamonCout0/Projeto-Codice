import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
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
    this.padding = const EdgeInsets.all(16),
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
        gradient: Efeitos.volume(cor),
        borderRadius: raio ?? BorderRadius.circular(Estilos.raio),
        border: Border.all(color: borda),
        boxShadow: Efeitos.sombraCartao,
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
    final raio = BorderRadius.circular(18);
    // Material próprio: o Ink pinta nele, e não num Material lá atrás (que
    // ficaria escondido sob um cartão colorido).
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: raio,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: raio,
            border: borda == null ? null : Border.all(color: borda!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(icone, color: cor, size: 15),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarraProgresso extends StatelessWidget {
  final double valor;
  final Color? cor;
  final double altura;

  const BarraProgresso(this.valor, {super.key, this.cor, this.altura = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: altura,
        color: cor,
        backgroundColor: Cores.trilho,
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
            Icon(icone, color: Cores.roxo, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(mensagem)),
          ],
        ),
      ),
    );
}
