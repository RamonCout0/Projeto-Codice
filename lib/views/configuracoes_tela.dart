import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/services/conversa_gemma.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

class ConfiguracoesTela extends StatefulWidget {
  const ConfiguracoesTela({super.key});

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  late final Ajustes _ajustes = context.read<Ajustes>();
  late final _endereco = TextEditingController(text: _ajustes.enderecoOllama);
  late final _modelo = TextEditingController(text: _ajustes.modelo);
  String? _resultadoTeste;
  bool _testando = false;

  @override
  void dispose() {
    _endereco.dispose();
    _modelo.dispose();
    super.dispose();
  }

  Future<void> _salvarETestar() async {
    FocusScope.of(context).unfocus();
    await _ajustes.alterar(() {
      _ajustes.enderecoOllama = _endereco.text.trim();
      _ajustes.modelo = _modelo.text.trim();
    });
    setState(() => _testando = true);
    final resultado = await ConversaGemma(
      endereco: _ajustes.enderecoOllama,
      modelo: _ajustes.modelo,
    ).testar();
    if (mounted) {
      setState(() {
        _testando = false;
        _resultadoTeste = resultado;
      });
    }
  }

  Widget _chave(
    String titulo,
    String subtitulo,
    bool valor,
    ValueChanged<bool> mudar,
  ) {
    return SwitchListTile(
      value: valor,
      title: Text(titulo),
      subtitle: Text(subtitulo),
      onChanged: (v) => _ajustes.alterar(() => mudar(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<Ajustes>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const CabecalhoDetalhe('Configurações'),
            const TituloGrande('Configurações'),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('CONVERSA (OLLAMA NO PC)', style: Estilos.secao),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _endereco,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'endereço do Ollama',
                      hintText: 'http://192.168.0.10:11434',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelo,
                    decoration: const InputDecoration(labelText: 'modelo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _testando ? null : _salvarETestar,
                    child: Text(_testando ? 'testando...' : 'salvar e testar'),
                  ),
                  if (_resultadoTeste != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _resultadoTeste!,
                        style: TextStyle(
                          color: _resultadoTeste!.startsWith('conectado ·')
                              ? Cores.verde
                              : Cores.ambar,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    'no celular, use o IP do PC na mesma rede Wi-Fi. '
                    'no emulador, http://10.0.2.2:11434. '
                    'no navegador do PC, http://localhost:11434.',
                    style: Estilos.legenda,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _chave(
              'Falas em Navidês',
              'tocar os bipes quando o seu NAVI conversa com outro',
              ajustes.falasEmNavides,
              (v) => ajustes.falasEmNavides = v,
            ),
            _chave(
              'Avisar encontros',
              'notificar quando um NAVI for encontrado por Bluetooth',
              ajustes.avisarEncontros,
              (v) => ajustes.avisarEncontros = v,
            ),
            _chave(
              'Relato da cidade',
              'resumo do que o seu NAVI fez na NAVICity enquanto você saiu',
              ajustes.relatoDaCidade,
              (v) => ajustes.relatoDaCidade = v,
            ),
          ],
        ),
      ),
    );
  }
}
