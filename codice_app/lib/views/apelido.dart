import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

class ApelidoScreen extends StatefulWidget {
  final String apelidoAtual;

  const ApelidoScreen({super.key, required this.apelidoAtual});

  @override
  State<ApelidoScreen> createState() => _ApelidoScreenState();
}

class _ApelidoScreenState extends State<ApelidoScreen> {
  static const List<String> sugestoes = ['Bipinho', 'Faísca', 'Nuvenzinha'];

  late final TextEditingController _campo =
      TextEditingController(text: widget.apelidoAtual);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final apelido = _campo.text.trim();
    if (apelido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um apelido antes de salvar.')),
      );
      return;
    }
    debugPrint('[Apelido] apelido confirmado');
    Navigator.pop(context, apelido);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabecalhoDetalhe('Encontros / apelido'),
            const TituloGrande(
              'Dar um apelido',
              subtitulo: 'a Frost vai usar esse nome quando falar dele.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _campo,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _salvar(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kPanel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in sugestoes)
                        ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          onPressed: () => _campo.text = s,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: const Color(0xFF0D0B13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('salvar apelido'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      debugPrint('[Apelido] Navigator.pop(context) sem valor');
                      Navigator.pop(context);
                    },
                    child: const Text('cancelar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
