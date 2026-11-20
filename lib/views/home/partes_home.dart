import 'package:flutter/material.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';

/// Aviso âmbar de quando a NAVI percebe dois fatos que se contradizem.
class CartaoPergunta extends StatelessWidget {
  const CartaoPergunta({super.key});

  @override
  Widget build(BuildContext context) {
    return Painel(
      cor: Cores.ambarFundo,
      borda: Cores.ambarBorda,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded, color: Cores.ambar, size: 17),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ela quer entender uma coisa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Cores.ambar,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '«Você mudou de emprego?»',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'dois fatos que ela guarda se contradizem.',
                  style: TextStyle(color: Cores.ambarSuave, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Pilula(
            'resolver',
            cor: Cores.sobreAmbar,
            fundo: Cores.ambar,
            borda: null,
          ),
        ],
      ),
    );
  }
}

/// Atalho da Home: ícone num quadrado tingido e o nome da ação.
class AcaoRapida extends StatelessWidget {
  final IconData icone;
  final String rotulo;

  const AcaoRapida(this.icone, this.rotulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Painel(
        altura: 88,
        cor: Cores.painel,
        borda: Cores.linha,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Cores.roxo.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icone, color: Cores.roxo, size: 22),
            ),
            const SizedBox(height: 7),
            Text(
              rotulo,
              style: const TextStyle(
                color: Cores.textoSuave,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vigor do NAVI num cartão, com a barra e o resumo.
class PainelVigor extends StatelessWidget {
  final int valor;

  const PainelVigor(this.valor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Painel(
      padding: const EdgeInsets.all(18),
      child: BarraVigor(valor),
    );
  }
}

class BarraVigor extends StatelessWidget {
  final int valor;

  const BarraVigor(this.valor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('VIGOR', style: Estilos.secao),
            const Spacer(),
            Text(
              '$valor',
              style: const TextStyle(
                color: Cores.verde,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BarraProgresso(valor / 100, altura: 8, cor: Cores.verde),
        const SizedBox(height: 10),
        const Text(
          'descansou bem, sem desgaste acumulado.',
          style: Estilos.legenda,
        ),
      ],
    );
  }
}
