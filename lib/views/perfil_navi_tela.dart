import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/models/perfil_navi.dart';
import 'package:codice_app/services/api_codice.dart';
import 'package:codice_app/services/conversa_gemma.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';

/// Nome, elemento, traços e gostos do NAVI. É daqui que o Gemma tira a
/// personalidade que interpreta na Conversa.
class PerfilNaviTela extends StatefulWidget {
  /// true: logo depois de criar a conta; ao salvar, segue para o app.
  final bool criando;
  const PerfilNaviTela({super.key, this.criando = false});

  @override
  State<PerfilNaviTela> createState() => _PerfilNaviTelaState();
}

class _PerfilNaviTelaState extends State<PerfilNaviTela> {
  late final Sessao _sessao = context.read<Sessao>();
  late PerfilNavi _perfil = _sessao.perfil;
  late final _nome = TextEditingController(text: _perfil.nome);
  late final _gostos = TextEditingController(text: _perfil.gostos);
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _gostos.dispose();
    super.dispose();
  }

  void _alternarTraco(Traco traco) {
    final tracos = [..._perfil.tracos];
    if (tracos.contains(traco)) {
      if (tracos.length == 1) return; // pelo menos um
      tracos.remove(traco);
    } else {
      if (tracos.length == PerfilNavi.maxTracos) tracos.removeAt(0);
      tracos.add(traco);
    }
    setState(() => _perfil = _perfil.copiar(tracos: tracos));
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      avisar(context, 'dê um nome ao seu NAVI', icone: Icons.edit_outlined);
      return;
    }
    final perfil = _perfil.copiar(
      nome: nome,
      gostos: _gostos.text.trim().replaceAll(RegExp(r'\s+'), ' '),
    );
    setState(() => _salvando = true);
    try {
      await _sessao.salvarPerfil(perfil);
      if (!mounted) return;
      avisar(context, '${perfil.nome} está pronta', icone: perfil.elemento.icone);
      if (widget.criando) {
        Navigator.of(context).pushReplacementNamed(Rotas.app);
      } else {
        Navigator.of(context).pop();
      }
    } on FalhaApi catch (falha) {
      if (mounted) avisar(context, falha.mensagem, icone: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elemento = _perfil.elemento;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.criando) const CabecalhoDetalhe('Personalidade'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Estilos.margem,
                  8,
                  Estilos.margem,
                  Estilos.margem,
                ),
                children: [
                  TituloGrande(
                    widget.criando ? 'Crie seu NAVI' : 'Personalidade',
                    subtitulo: 'é assim que o seu NAVI pensa e fala com você.',
                  ),
                  const SizedBox(height: 18),
                  const Text('NOME', style: Estilos.secao),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nome,
                    maxLength: PerfilNavi.maxNome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'como seu NAVI se chama',
                      counterText: '',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  const Text('ELEMENTO', style: Estilos.secao),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.95,
                    children: [
                      for (final e in Elemento.values)
                        _CartaoElemento(
                          elemento: e,
                          escolhido: e == elemento,
                          onTap: () =>
                              setState(() => _perfil = _perfil.copiar(elemento: e)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    elemento.jeito,
                    style: Estilos.legenda.copyWith(color: elemento.cor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('PERSONALIDADE', style: Estilos.secao),
                      const Spacer(),
                      Text(
                        '${_perfil.tracos.length} de ${PerfilNavi.maxTracos}',
                        style: Estilos.legenda,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in Traco.values)
                        FilterChip(
                          label: Text(t.titulo),
                          selected: _perfil.tracos.contains(t),
                          onSelected: (_) => _alternarTraco(t),
                          tooltip: t.jeito,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('DO QUE GOSTA', style: Estilos.secao),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gostos,
                    maxLength: PerfilNavi.maxGostos,
                    decoration: const InputDecoration(
                      hintText: 'ex.: livros de aventura, chuva, gatos',
                      prefixIcon: Icon(Icons.favorite_border, size: 18),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _Previa(
                    perfil: _perfil.copiar(
                      nome: _nome.text.trim().isEmpty ? 'seu NAVI' : _nome.text.trim(),
                      gostos: _gostos.text.trim(),
                    ),
                  ),
                  if (!_sessao.conectado) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'sem conta, a personalidade fica só neste aparelho.',
                      style: Estilos.legenda,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Estilos.margem,
                0,
                Estilos.margem,
                Estilos.margem,
              ),
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(elemento.icone, size: 18),
                label: Text(widget.criando ? 'criar meu NAVI' : 'salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoElemento extends StatelessWidget {
  final Elemento elemento;
  final bool escolhido;
  final VoidCallback onTap;

  const _CartaoElemento({
    required this.elemento,
    required this.escolhido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = elemento.cor;
    return Semantics(
      selected: escolhido,
      button: true,
      label: 'elemento ${elemento.titulo}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: escolhido ? cor.withValues(alpha: 0.14) : Cores.painel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: escolhido ? cor : Cores.borda,
              width: escolhido ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(elemento.icone, color: escolhido ? cor : Cores.textoApagado, size: 22),
              const SizedBox(height: 6),
              Text(
                elemento.titulo,
                style: TextStyle(
                  color: escolhido ? Colors.white : Cores.textoSecundario,
                  fontSize: 11,
                  fontWeight: escolhido ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O mesmo texto de personalidade que vai para o Gemma.
class _Previa extends StatelessWidget {
  final PerfilNavi perfil;
  const _Previa({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Painel(
      cor: Cores.cartaoClaro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 16, color: perfil.elemento.cor),
              const SizedBox(width: 6),
              const Text('COMO O GEMMA VAI INTERPRETAR', style: Estilos.secao),
            ],
          ),
          const SizedBox(height: 8),
          Text(ConversaGemma.descreverPersonalidade(perfil), style: Estilos.corpoSuave),
        ],
      ),
    );
  }
}
