import 'package:flutter/material.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/icones.dart';

/// Cartão para quando a cidade ainda não deu dados: conectando, fora do ar
/// ou sem conexão iniciada.
class AvisoCidade extends StatelessWidget {
  final CidadeNavi cidade;

  const AvisoCidade(this.cidade, {super.key});

  @override
  Widget build(BuildContext context) {
    final erro = cidade.estado == EstadoCidade.erro;
    final conectando = cidade.estado == EstadoCidade.conectando;
    return Painel(
      borda: erro ? Cores.vermelho.withValues(alpha: 0.4) : Cores.borda,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (conectando)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            IconeCodice(
              erro ? Ic.nuvemOff : Ic.cidade,
              color: erro ? Cores.vermelho : Cores.textoApagado,
              size: 32,
            ),
          const SizedBox(height: 12),
          Text(
            conectando
                ? 'Conectando à NAVICity…'
                : erro
                ? 'A NAVICity não respondeu'
                : 'Sem conexão com a NAVICity',
            style: Estilos.tituloDialogo,
          ),
          const SizedBox(height: 6),
          Text(
            erro
                ? (cidade.erro ?? 'Tente de novo em instantes.')
                : 'Os lugares e encontros aparecem assim que a cidade responder.',
            textAlign: TextAlign.center,
            style: Estilos.legenda,
          ),
          if (!conectando) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: cidade.tentarDeNovo,
              child: const Text('tentar de novo'),
            ),
          ],
        ],
      ),
    );
  }
}
