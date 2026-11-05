import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/models/navi_encontrado.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/views/apelido.dart';

class NaviScreen extends StatefulWidget {
  final NaviEncontrado navi;

  const NaviScreen({super.key, required this.navi});

  @override
  State<NaviScreen> createState() => _NaviScreenState();
}

class _NaviScreenState extends State<NaviScreen> {
  /// Empilha mais uma tela NA MESMA ABA e espera o resultado do pop.
  Future<void> _darApelido() async {
    final navi = widget.navi;
    debugPrint('[Encontros] pushNamed<String>(${Rotas.apelido}, '
        'arguments: "${navi.comoChamar}")');
    final novo = await Navigator.pushNamed<String>(
      context,
      Rotas.apelido,
      arguments: navi.comoChamar,
    );
    debugPrint('[Encontros] ApelidoScreen devolveu: '
        '${novo == null ? 'nada (cancelou)' : '"$novo"'}');
    if (!mounted || novo == null || novo.isEmpty) return;
    context.read<EstadoCodice>().alterarApelido(navi.nome, novo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('a Frost agora chama ${navi.nome} de "$novo"'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoCodice>();
    final navi = estado.obterNavi(widget.navi.nome) ?? widget.navi;
    return Material(
      color: kBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabecalhoDetalhe('Encontros / ${navi.nome}'),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B3A),
                  shape: BoxShape.circle,
                  border: Border.all(color: navi.cor),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: navi.cor,
                  size: 46,
                ),
              ),
            ),
            TituloGrande(
              navi.comoChamar,
              subtitulo: navi.apelido == null
                  ? navi.quando
                  : 'apelido de ${navi.nome} · ${navi.quando}',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'afinidade ${navi.afinidade}%',
                    style: const TextStyle(color: kPurple2, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: navi.afinidade / 100,
                      minHeight: 6,
                      color: navi.cor,
                      backgroundColor: const Color(0xFF2A2735),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '«${navi.relato}»',
                    style: const TextStyle(
                      color: Color(0xFFC5C1CB),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _darApelido,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        navi.apelido == null
                            ? 'dar um apelido'
                            : 'mudar apelido',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: const Color(0xFF0D0B13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
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
