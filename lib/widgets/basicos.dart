import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/icones.dart';

/// Caixa com fundo e borda: a base visual de quase todos os cartões.
class Painel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fundo e borda; sem valor, usam as cores do cartão do tema atual.
  final Color? cor;
  final Color? borda;
  final BorderRadius? raio;
  final double? altura;
  final EdgeInsetsGeometry? margem;

  const Painel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.cor,
    this.borda,
    this.raio,
    this.altura,
    this.margem,
  });

  @override
  Widget build(BuildContext context) {
    final fundo = cor ?? Cores.cartao;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: altura,
      margin: margem,
      padding: padding,
      decoration: BoxDecoration(
        gradient: Efeitos.volume(fundo),
        borderRadius: raio ?? BorderRadius.circular(Estilos.raio),
        border: Border.all(color: borda ?? Cores.borda),
        boxShadow: Efeitos.sombraCartao,
      ),
      child: child,
    );
  }
}

/// "Sem valor": distingue o padrão (borda roxa) de `borda: null` (sem borda).
const _bordaPadrao = Color(0x01000001);

/// Selo pequeno com ícone opcional ("ficha", "off-line", "3 memórias").
class Pilula extends StatelessWidget {
  final String texto;
  final Ic? icone;
  final Color? cor;
  final Color? fundo;
  final Color? borda;
  final VoidCallback? onTap;

  const Pilula(
    this.texto, {
    super.key,
    this.icone,
    this.cor,
    this.fundo,
    this.borda = _bordaPadrao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(18);
    final corTexto = cor ?? Cores.roxo;
    final corFundo = fundo ?? Cores.roxoFundo;
    final corBorda = borda == _bordaPadrao ? Cores.roxoBorda : borda;
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
            color: corFundo,
            borderRadius: raio,
            border: corBorda == null ? null : Border.all(color: corBorda),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                IconeCodice(icone!, color: corTexto, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: corTexto,
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

/// Barra de progresso com ponta arredondada, degradê e brilho. Anima quando
/// o valor muda.
class BarraProgresso extends StatelessWidget {
  final double valor;
  final Color? cor;
  final double altura;

  const BarraProgresso(this.valor, {super.key, this.cor, this.altura = 6});

  @override
  Widget build(BuildContext context) {
    final destaque = cor ?? Cores.ciano;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: valor.clamp(0, 1)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Container(
        height: altura,
        decoration: BoxDecoration(
          color: Cores.trilho,
          borderRadius: BorderRadius.circular(altura),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v == 0 ? 0.0 : v.clamp(0.02, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(altura),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(destaque, Colors.white, 0.28)!,
                  destaque,
                ],
              ),
              boxShadow: Efeitos.brilho(destaque, forca: 0.35, desfoque: 8),
            ),
          ),
        ),
      ),
    );
  }
}

/// SnackBar única: esconde a anterior para os avisos não formarem fila.
void avisar(
  BuildContext context,
  String mensagem, {
  Ic icone = Ic.info,
  SnackBarAction? acao,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: acao,
        content: Row(
          children: [
            IconeCodice(icone, color: Cores.roxo, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(mensagem)),
          ],
        ),
      ),
    );
}
