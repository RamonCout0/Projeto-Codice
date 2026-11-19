import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

/// Devolve o apelido escolhido no Navigator.pop (ou nada, se cancelar).
class ApelidoTela extends StatefulWidget {
  final String apelidoAtual;

  const ApelidoTela({super.key, required this.apelidoAtual});

  @override
  State<ApelidoTela> createState() => _ApelidoTelaState();
}

class _ApelidoTelaState extends State<ApelidoTela> {
  static const _sugestoes = ['Bipinho', 'Faísca', 'Nuvenzinha'];

  late final _campo = TextEditingController(text: widget.apelidoAtual);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final apelido = _campo.text.trim();
    if (apelido.isEmpty) {
      avisar(context, 'Digite um apelido antes de salvar.');
      return;
    }
    Navigator.pop(context, apelido);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.fundo,
      child: ListView(
        children: [
          const CabecalhoDetalhe('Encontros / apelido'),
          TituloGrande(
            'Dar um apelido',
            subtitulo:
                '${context.read<Sessao>().perfil.nome} vai usar esse nome quando falar dele.',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _campo,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _salvar(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Cores.painel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in _sugestoes)
                      ActionChip(
                        label: Text(s),
                        onPressed: () => _campo.text = s,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('salvar apelido'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('cancelar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
