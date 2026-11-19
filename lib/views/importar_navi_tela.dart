import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/basicos.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/widgets/navi_3d.dart';

/// Traz o modelo .vrm da NAVI e as animações (.vrma ou .fbx do Mixamo)
/// para dentro do app.
/// Os arquivos ficam só neste aparelho.
class ImportarNaviTela extends StatefulWidget {
  const ImportarNaviTela({super.key});

  @override
  State<ImportarNaviTela> createState() => _ImportarNaviTelaState();
}

class _ImportarNaviTelaState extends State<ImportarNaviTela> {
  bool _ocupado = false;

  Future<void> _executar(Future<String?> Function() acao) async {
    setState(() => _ocupado = true);
    final erro = await acao();
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (erro != null) avisar(context, erro, icone: Icons.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    final arquivos = context.watch<ArquivosNavi>();
    final modelo = arquivos.modelo;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const CabecalhoDetalhe('Importar NAVI'),
            const TituloGrande(
              'Importar NAVI',
              subtitulo: 'traga o modelo 3D e as animações do seu NAVI.',
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('MODELO (.vrm)', style: Estilos.secao),
                  const SizedBox(height: 8),
                  Painel(
                    child: Row(
                      children: [
                        AvatarNavi(
                          largura: 56,
                          altura: 56,
                          raio: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modelo == null
                                    ? 'nenhum modelo importado'
                                    : arquivos.nomeModelo ?? 'modelo importado',
                                style: Estilos.tituloDialogo,
                              ),
                              Text(
                                modelo == null
                                    ? 'a NAVI fica vazia até você importar um'
                                    : arquivos.modeloEmbutido
                                    ? 'da pasta assets/navi_local do projeto'
                                    : Navi3D.suportado
                                    ? 'a foto aparece depois que ela carregar'
                                    : 'o 3D aparece no celular ou na web',
                                style: Estilos.legenda,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _ocupado
                        ? null
                        : () => _executar(arquivos.importarModelo),
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: Text(
                      arquivos.modeloImportado
                          ? 'trocar modelo'
                          : 'escolher arquivo .vrm',
                    ),
                  ),
                  if (arquivos.modeloImportado)
                    TextButton(
                      onPressed: _ocupado
                          ? null
                          : () => _executar(() async {
                              await arquivos.removerModelo();
                              return null;
                            }),
                      child: const Text('remover modelo'),
                    ),
                  const SizedBox(height: 20),
                  const Text('ANIMAÇÕES (.vrma OU MIXAMO .fbx)', style: Estilos.secao),
                  const SizedBox(height: 4),
                  const Text(
                    'opcional. sem elas, a NAVI usa movimentos simples feitos pelo app. '
                    'do mixamo.com: baixe em FBX Binary, "Without Skin".',
                    style: Estilos.legenda,
                  ),
                  const SizedBox(height: 8),
                  for (final gesto in Gesto.values)
                    _LinhaAnimacao(
                      gesto: gesto,
                      importada: arquivos.animacaoImportada(gesto),
                      embutida: arquivos.animacoes.containsKey(gesto),
                      ocupado: _ocupado,
                      aoImportar: () =>
                          _executar(() => arquivos.importarAnimacao(gesto)),
                      aoRemover: () => _executar(() async {
                        await arquivos.removerAnimacao(gesto);
                        return null;
                      }),
                    ),
                  const SizedBox(height: 16),
                  const Painel(
                    cor: Cores.cartaoClaro,
                    child: Text(
                      'copie os arquivos para o celular (cabo, Drive, e-mail) '
                      'e escolha aqui. eles ficam só neste aparelho e não vão '
                      'para o GitHub: cada modelo tem a sua licença. '
                      'na web, o importado vale só até fechar a aba: para '
                      'apresentar, use a pasta assets/navi_local.',
                      style: Estilos.legenda,
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

class _LinhaAnimacao extends StatelessWidget {
  final Gesto gesto;
  final bool importada;

  /// Tem uma em assets/navi_local (vale quando nada foi importado).
  final bool embutida;
  final bool ocupado;
  final VoidCallback aoImportar;
  final VoidCallback aoRemover;

  const _LinhaAnimacao({
    required this.gesto,
    required this.importada,
    required this.embutida,
    required this.ocupado,
    required this.aoImportar,
    required this.aoRemover,
  });

  @override
  Widget build(BuildContext context) {
    final tem = importada || embutida;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        tem ? Icons.check_circle : Icons.radio_button_unchecked,
        color: tem ? Cores.verde : Cores.textoFraco,
      ),
      title: Text(gesto.titulo),
      subtitle: Text(
        importada || !embutida ? gesto.quando : '${gesto.quando} · do projeto',
      ),
      trailing: importada
          ? IconButton(
              tooltip: 'remover',
              onPressed: ocupado ? null : aoRemover,
              icon: const Icon(Icons.delete_outline),
            )
          : TextButton(
              onPressed: ocupado ? null : aoImportar,
              child: const Text('importar'),
            ),
    );
  }
}
