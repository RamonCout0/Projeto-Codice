import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/navegacao_abas.dart';
import 'package:codice_app/controllers/cidade_navi.dart';
import 'package:codice_app/controllers/estado_codice.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/services/narracao.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/views/diario/dialogos_diario.dart';
import 'package:codice_app/widgets/basicos.dart';

/// O que está acontecendo agora, sempre com dados reais:
///  1. uma pergunta que a NAVI quer fazer (duas memórias se contradizem);
///  2. um problema para falar com a cidade, com botão de tentar de novo;
///  3. o último acontecimento da NAVICity com o NAVI do usuário;
///  4. onde o NAVI está, quando ainda não aconteceu nada.
class CartaoNovidade extends StatelessWidget {
  const CartaoNovidade({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoCodice>();
    final cidade = context.watch<CidadeNavi>();
    final nome = context.watch<Sessao>().perfil.nome;

    final pergunta = estado.pergunta;
    if (pergunta != null) {
      return _Cartao(
        ambar: true,
        icone: Icons.favorite_border_rounded,
        rotulo: '$nome quer entender uma coisa',
        titulo: '«${pergunta.texto}»',
        texto: 'duas coisas que ela guarda se contradizem.',
        acao: 'resolver',
        aoTocar: () => _resolver(context, pergunta),
      );
    }

    if (cidade.estado == EstadoCidade.erro && cidade.fatos.isEmpty) {
      return _Cartao(
        icone: Icons.cloud_off_outlined,
        cor: Cores.vermelho,
        rotulo: 'NAVICITY FORA DO AR',
        titulo: 'Não consegui falar com a cidade',
        texto: cidade.erro ?? 'Tente de novo em instantes.',
        acao: 'tentar de novo',
        aoTocar: cidade.tentarDeNovo,
      );
    }

    if (cidade.estado == EstadoCidade.conectando || cidade.situacao == null) {
      return const _Cartao(
        icone: Icons.sync,
        rotulo: 'NAVICITY',
        titulo: 'Conectando…',
        texto: 'Entrando na cidade com o seu NAVI.',
        carregando: true,
      );
    }

    final ultimo = cidade.ultimoFato;
    if (ultimo != null) {
      return _Cartao(
        icone: Icons.location_city,
        rotulo: 'NA CIDADE · ${cidade.quando(ultimo.quandoSegundos).toUpperCase()}',
        titulo: narrar(ultimo, nome),
        texto: 'Toque para ver os encontros.',
        aoTocar: () => context.read<NavegacaoAbas>().irPara(4),
      );
    }

    return _Cartao(
      icone: Icons.location_city,
      rotulo: 'NA CIDADE',
      titulo: '$nome está em ${cidade.situacao!.area}',
      texto: 'Ainda não aconteceu nada. Em breve ela encontra alguém.',
      aoTocar: () => context.read<NavegacaoAbas>().irPara(3),
    );
  }

  Future<void> _resolver(BuildContext context, PerguntaPendente pergunta) async {
    final estado = context.read<EstadoCodice>();
    final mudou = await perguntarContradicao(context, pergunta.antiga);
    if (!context.mounted || mudou == null) return;
    if (mudou) estado.esquecerMemoria(pergunta.antiga);
    estado.encerrarPergunta();
    avisar(
      context,
      mudou ? 'memória antiga substituída' : 'as duas memórias foram mantidas',
      icone: Icons.sync_alt,
    );
  }
}

class _Cartao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String titulo;
  final String texto;
  final String? acao;
  final VoidCallback? aoTocar;
  final bool ambar;
  final bool carregando;
  final Color cor;

  const _Cartao({
    required this.icone,
    required this.rotulo,
    required this.titulo,
    required this.texto,
    this.acao,
    this.aoTocar,
    this.ambar = false,
    this.carregando = false,
    this.cor = Cores.roxo,
  });

  @override
  Widget build(BuildContext context) {
    final destaque = ambar ? Cores.ambar : cor;
    final conteudo = Painel(
      cor: ambar ? Cores.ambarFundo : Cores.cartao,
      borda: ambar ? Cores.ambarBorda : destaque.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icone, color: destaque, size: 17),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: destaque,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(
                    color: ambar ? Cores.ambarSuave : Cores.textoApagado,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (carregando) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ] else if (acao != null) ...[
            const SizedBox(width: 12),
            Pilula(
              acao!,
              cor: ambar ? Cores.sobreAmbar : Cores.sobreRoxo,
              fundo: ambar ? Cores.ambar : destaque,
              borda: null,
            ),
          ],
        ],
      ),
    );
    if (aoTocar == null) return conteudo;
    return GestureDetector(onTap: aoTocar, child: conteudo);
  }
}

/// Atalho da Home: ícone num quadrado tingido e o nome da ação.
class AcaoRapida extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  const AcaoRapida(this.icone, this.rotulo, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Painel(
          altura: 88,
          cor: Cores.painel,
          borda: Cores.linha,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Cores.roxo.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: Cores.roxo, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                rotulo,
                style: const TextStyle(
                  color: Cores.textoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Crescimento da NAVI: a idade sobe com as memórias guardadas.
class PainelCrescimento extends StatelessWidget {
  const PainelCrescimento({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoCodice>();
    final nome = context.watch<Sessao>().perfil.nome;
    final adulta = estado.idade >= EstadoCodice.idadeMaxima;
    final faltam = estado.faltamParaCrescer;
    return Painel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('CRESCIMENTO', style: Estilos.secao),
              const Spacer(),
              Text(
                '${estado.idade} anos',
                style: const TextStyle(
                  color: Cores.verde,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BarraProgresso(estado.progressoIdade, altura: 8, cor: Cores.verde),
          const SizedBox(height: 10),
          Text(
            adulta
                ? '$nome chegou aos 18: a primeira etapa está completa.'
                : '${estado.memorias.length} memórias guardadas. Mais '
                      '$faltam ${faltam == 1 ? 'memória' : 'memórias'} e $nome '
                      'faz ${estado.idade + 1} anos.',
            style: Estilos.legenda,
          ),
        ],
      ),
    );
  }
}
