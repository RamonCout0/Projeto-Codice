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
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Cores.ambar, size: 15),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'ela quer entender uma coisa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Cores.ambar,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7),
                Text(
                  '«Você mudou de emprego?»',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'dois fatos que ela guarda se contradizem.',
                  style: TextStyle(color: Color(0xFF918676), fontSize: 10),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
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

class AcaoRapida extends StatelessWidget {
  final IconData icone;
  final String rotulo;

  const AcaoRapida(this.icone, this.rotulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Painel(
        altura: 68,
        cor: Cores.painel,
        borda: Cores.linha,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: Cores.roxo, size: 18),
            const SizedBox(height: 7),
            Text(
              rotulo,
              style: const TextStyle(
                color: Color(0xFFB2ADBE),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
                color: Cores.textoSecundario,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BarraProgresso(valor / 100, altura: 7),
        const SizedBox(height: 6),
        const Text(
          'descansou bem, sem desgaste acumulado.',
          style: Estilos.legenda,
        ),
      ],
    );
  }
}
