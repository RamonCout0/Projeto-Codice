import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/ui/imagens.dart';

class BotaoMenu extends StatelessWidget {
  const BotaoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: 'abrir menu',
        child: InkResponse(
          radius: 18,
          onTap: () {
            debugPrint('[drawer] abrir');
            Scaffold.of(context).openDrawer();
          },
          child: const Icon(Icons.menu, size: 18, color: Color(0xFFC5C1CB)),
        ),
      ),
    );
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  /// push: Configurações entra POR CIMA do app na pilha raiz. O voltar
  /// tira ela e o app reaparece do jeito que estava.
  void _configuracoes(BuildContext context) {
    Scaffold.of(context).closeDrawer();
    debugPrint('[drawer] Configurações: pushNamed(${Rotas.configuracoes})');
    Navigator.of(context).pushNamed(Rotas.configuracoes);
  }

  /// Modal simples: não é uma tela, é um diálogo por cima.
  void _sobre(BuildContext context) {
    Scaffold.of(context).closeDrawer();
    debugPrint('[drawer] Sobre: showDialog');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kLine),
        ),
        icon: const Icon(Icons.auto_stories_outlined, color: kPurple),
        title: const Text(
          'Códice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Um diário pessoal onde uma criatura digital aprende com a '
          'convivência.\n\n'
          'Disciplina de Desenvolvimento para Dispositivos Móveis.\n'
          'Ramon Couto Santo e Aaron Guerra Goldberg.',
          style: TextStyle(
            color: Color(0xFFE4E0E9),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('fechar'),
          ),
        ],
      ),
    );
  }

  /// pushReplacement: o app SAI da pilha e o login entra no lugar dele.
  /// Depois do logout, o voltar não consegue retornar para dentro do app.
  void _sair(BuildContext context) {
    debugPrint('[drawer] Sair: pushReplacementNamed(${Rotas.login})');
    Navigator.of(context).pushReplacementNamed(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kPanel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C5C2)),
                    ),
                    child: ClipOval(
                      child: Image(
                        image: frostRostoImage,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'NAVI · 8 anos · criança',
                        style: TextStyle(color: kPurple2, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: kLine, height: 1),
            const SizedBox(height: 8),
            _item(
              icone: Icons.settings_outlined,
              titulo: 'Configurações',
              subtitulo: 'sons, avisos e cidade',
              onTap: () => _configuracoes(context),
            ),
            _item(
              icone: Icons.info_outline,
              titulo: 'Sobre',
              subtitulo: 'o que é o Códice',
              onTap: () => _sobre(context),
            ),
            const Spacer(),
            const Divider(color: kLine, height: 1),
            _item(
              icone: Icons.logout,
              titulo: 'Sair',
              subtitulo: 'voltar para a tela de entrada',
              cor: const Color(0xFFFF8A8A),
              onTap: () => _sair(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color cor = const Color(0xFFE4E0E9),
  }) {
    return ListTile(
      leading: Icon(icone, color: cor, size: 20),
      title: Text(titulo, style: TextStyle(color: cor, fontSize: 13)),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(color: Color(0xFF8B8498), fontSize: 10),
      ),
      onTap: onTap,
    );
  }
}
