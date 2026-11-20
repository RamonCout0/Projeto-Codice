import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/models/ajustes.dart';
import 'package:codice_app/services/api_navicity.dart' show enderecoNavicity;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const CabecalhoDetalhe('Configurações'),
            const TituloGrande('Configurações'),
            const SizedBox(height: 14),
            const _SecaoAparencia(),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            Padding(
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
                  Text(
                    'no celular, use o IP do PC na mesma rede Wi-Fi. '
                    'no emulador, http://10.0.2.2:11434. '
                    'no navegador do PC, http://localhost:11434.',
                    style: Estilos.legenda,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const Divider(),
            const _SecaoCidade(),
          ],
        ),
      ),
    );
  }
}


/// Aparência: sistema, claro ou noturno. Vale na hora e fica guardado.
class _SecaoAparencia extends StatelessWidget {
  const _SecaoAparencia();

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<Ajustes>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APARÊNCIA', style: Estilos.secao),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ModoTema>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ModoTema.sistema, label: Text('Sistema')),
                ButtonSegment(value: ModoTema.claro, label: Text('Claro')),
                ButtonSegment(value: ModoTema.escuro, label: Text('Noturno')),
              ],
              selected: {ajustes.modoTema},
              onSelectionChanged: (v) => ajustes.alterar(() => ajustes.modoTema = v.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema segue o modo claro ou escuro do aparelho.',
            style: Estilos.legenda,
          ),
        ],
      ),
    );
  }
}

/// Estado real da conexão com a NAVICity, com botão para reconectar.
class _SecaoCidade extends StatelessWidget {
  const _SecaoCidade();

  @override
  Widget build(BuildContext context) {
    final cidade = context.watch<CidadeNavi>();
    final (texto, cor) = switch (cidade.estado) {
      EstadoCidade.conectada => ('conectada', Cores.verde),
      EstadoCidade.conectando => ('conectando…', Cores.ambar),
      EstadoCidade.erro => ('sem resposta', Cores.vermelho),
      EstadoCidade.desconectada => ('desconectada', Cores.textoApagado),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NAVICITY', style: Estilos.secao),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(enderecoNavicity, style: Estilos.legenda),
          if (cidade.erro != null && cidade.estado == EstadoCidade.erro) ...[
            const SizedBox(height: 4),
            Text(cidade.erro!, style: Estilos.legenda),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: cidade.estado == EstadoCidade.conectando ? null : cidade.tentarDeNovo,
            child: const Text('reconectar'),
          ),
        ],
      ),
    );
  }
}
