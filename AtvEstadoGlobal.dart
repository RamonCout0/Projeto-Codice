// ============================================================
// VERSÃO ENXUTA — só para leitura/demonstração do Provider.
// O app completo está em AtvNavegacao_provider.dart.
//
// Fluxo: lista (Encontros) -> detalhe do NAVI -> tela de apelido.
// Quando o apelido muda, a LISTA e o DETALHE reagem juntos,
// porque os dois leem o mesmo EstadoCodice.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ------------------------------------------------------------
// 1) MODELO
// ------------------------------------------------------------
class NaviEncontrado {
  final String nome;
  final int afinidade;
  String? apelido;

  NaviEncontrado(this.nome, this.afinidade);

  String get comoChamar => apelido ?? nome;
}

// ------------------------------------------------------------
// 2) ESTADO GLOBAL (fora da UI)
//    Guarda os dados e avisa os widgets com notifyListeners().
// ------------------------------------------------------------
class EstadoCodice extends ChangeNotifier {
  final List<NaviEncontrado> _navis = [
    NaviEncontrado('Pixel', 72),
    NaviEncontrado('Bolota', 45),
    NaviEncontrado('Nimbus', 88),
  ];

  List<NaviEncontrado> get navis => List.unmodifiable(_navis);

  NaviEncontrado? obterNavi(String nome) {
    for (final navi in _navis) {
      if (navi.nome == nome) return navi;
    }
    return null;
  }

  void alterarApelido(String nome, String novoApelido) {
    final navi = obterNavi(nome);
    if (navi == null || novoApelido.trim().isEmpty) return;

    navi.apelido = novoApelido.trim();
    notifyListeners(); // <- todo widget que faz watch() é reconstruído
  }
}

// ------------------------------------------------------------
// 3) REGISTRO DO PROVIDER (acima do MaterialApp)
// ------------------------------------------------------------
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => EstadoCodice(),
      child: const MaterialApp(home: ListaScreen()),
    ),
  );
}

// ------------------------------------------------------------
// 4) WIDGET A — lista: LÊ o estado (watch)
// ------------------------------------------------------------
class ListaScreen extends StatelessWidget {
  const ListaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navis = context.watch<EstadoCodice>().navis;

    return Scaffold(
      appBar: AppBar(title: const Text('Encontros')),
      body: ListView.builder(
        itemCount: navis.length,
        itemBuilder: (_, i) {
          final navi = navis[i];
          return ListTile(
            title: Text(navi.comoChamar),
            subtitle: Text(
              navi.apelido == null
                  ? 'afinidade ${navi.afinidade}%'
                  : '${navi.nome} · afinidade ${navi.afinidade}%',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetalheScreen(nome: navi.nome)),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// 5) WIDGET B — detalhe: também LÊ o mesmo estado (watch)
//    e ALTERA o estado (read) depois que a tela de apelido volta.
// ------------------------------------------------------------
class DetalheScreen extends StatelessWidget {
  final String nome;

  const DetalheScreen({super.key, required this.nome});

  Future<void> _darApelido(BuildContext context, NaviEncontrado navi) async {
    final novo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ApelidoScreen(apelidoAtual: navi.comoChamar),
      ),
    );
    if (!context.mounted || novo == null || novo.isEmpty) return;

    // read(): só chama o método, não precisa reconstruir por isso.
    context.read<EstadoCodice>().alterarApelido(navi.nome, novo);
  }

  @override
  Widget build(BuildContext context) {
    final navi = context.watch<EstadoCodice>().obterNavi(nome)!;

    return Scaffold(
      appBar: AppBar(title: Text(navi.comoChamar)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome original: ${navi.nome}'),
            Text('Apelido: ${navi.apelido ?? '(nenhum)'}'),
            Text('Afinidade: ${navi.afinidade}%'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _darApelido(context, navi),
              child: Text(navi.apelido == null ? 'dar apelido' : 'mudar apelido'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// 6) Tela de apelido — só devolve o texto com Navigator.pop.
//    Não mexe no estado global; quem decide é a tela anterior.
// ------------------------------------------------------------
class ApelidoScreen extends StatefulWidget {
  final String apelidoAtual;

  const ApelidoScreen({super.key, required this.apelidoAtual});

  @override
  State<ApelidoScreen> createState() => _ApelidoScreenState();
}

class _ApelidoScreenState extends State<ApelidoScreen> {
  // Estado LOCAL legítimo: o controller do campo de texto.
  late final TextEditingController _campo =
      TextEditingController(text: widget.apelidoAtual);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dar um apelido')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _campo),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _campo.text.trim()),
              child: const Text('salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
