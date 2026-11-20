import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/efeitos.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/icones.dart';

class BotaoMenu extends StatelessWidget {
  const BotaoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'abrir menu',
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: IconeCodice(Ic.menu, size: 24, color: Cores.textoSuave),
    );
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  void _abrir(BuildContext context, String rota) {
    Scaffold.of(context).closeDrawer();
    Navigator.of(context).pushNamed(rota);
  }

  void _sobre(BuildContext context) {
    Scaffold.of(context).closeDrawer();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: IconeCodice(Ic.livroAberto, color: Cores.roxo),
        title: const Text('Códice'),
        content: const Text(
          'Um diário pessoal onde uma criatura digital aprende com a '
          'convivência.\n\n'
          'Disciplina de Desenvolvimento para Dispositivos Móveis.\n'
          'Ramon Couto Santo e Aaron Guerra Goldberg.',
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

  /// Sai da conta (se houver) e volta para a entrada. pushReplacement:
  /// depois de sair, o voltar não retorna para o app.
  Future<void> _sair(BuildContext context) async {
    final navegador = Navigator.of(context);
    final sessao = context.read<Sessao>();
    if (sessao.conectado) {
      try {
        await sessao.sair();
      } catch (_) {
        // Mesmo sem apagar do armazenamento, a sessão some desta tela.
      }
    }
    if (!context.mounted) return;
    context.read<CidadeNavi>().desconectar();
    context.read<NavegacaoAbas>().irPara(0);
    navegador.pushReplacementNamed(Rotas.inicio);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<Sessao>();
    final perfil = sessao.perfil;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: perfil.elemento.cor, width: 1.5),
                      boxShadow: Efeitos.brilho(perfil.elemento.cor, forca: 0.3, desfoque: 14),
                    ),
                    child: const AvatarNavi(
                      largura: 60,
                      altura: 60,
                      redondo: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nome,
                          style: Estilos.tituloDialogo,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${perfil.elemento.titulo} · ${context.watch<EstadoCodice>().idade} anos · ${context.watch<EstadoCodice>().fase}',
                          style: TextStyle(color: perfil.elemento.cor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (sessao.usuario != null)
                          Text('@${sessao.usuario}', style: Estilos.legenda),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _Item(
              icone: Ic.navi,
              titulo: 'Personalidade',
              subtitulo: 'nome, elemento e jeito de ser',
              onTap: () => _abrir(context, Rotas.perfil),
            ),
            _Item(
              icone: Ic.cubo,
              titulo: 'Importar NAVI',
              subtitulo: 'modelo 3D (.vrm) e animações',
              onTap: () => _abrir(context, Rotas.importar),
            ),
            _Item(
              icone: Ic.config,
              titulo: 'Configurações',
              subtitulo: 'aparência, conversa e cidade',
              onTap: () => _abrir(context, Rotas.configuracoes),
            ),
            _Item(
              icone: Ic.info,
              titulo: 'Sobre',
              subtitulo: 'o que é o Códice',
              onTap: () => _sobre(context),
            ),
            const Spacer(),
            const Divider(height: 1),
            _Item(
              icone: Ic.sair,
              titulo: sessao.conectado ? 'Sair da conta' : 'Sair',
              subtitulo: sessao.conectado
                  ? 'esquece a sessão neste aparelho'
                  : 'voltar para a tela de entrada',
              cor: Cores.vermelho,
              onTap: () => _sair(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Ic icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final Color? cor;

  const _Item({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconeCodice(icone, color: cor ?? Cores.texto, size: 22),
      title: Text(titulo, style: TextStyle(color: cor ?? Cores.texto, fontSize: 15, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      subtitle: Text(subtitulo),
      onTap: onTap,
    );
  }
}
