import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/navi_3d.dart';

enum Enquadramento { corpo, busto, rosto }

/// O único lugar do app que desenha a NAVI.
/// - corpo/busto: o modelo 3D animado (importado ou em assets/navi_local);
/// - rosto: a foto tirada do próprio modelo depois que ele carrega.
/// Sem modelo, fica um espaço vazio convidando a importar um.
class AvatarNavi extends StatelessWidget {
  final Enquadramento enquadramento;
  final double? largura;
  final double? altura;
  final BorderRadius? raio;
  final bool redondo;
  final Alignment alinhamento;
  final Humor humor;
  final bool falando;

  const AvatarNavi({
    super.key,
    this.enquadramento = Enquadramento.rosto,
    this.largura,
    this.altura,
    this.raio,
    this.redondo = false,
    this.alinhamento = Alignment.center,
    this.humor = Humor.esperando,
    this.falando = false,
  });

  @override
  Widget build(BuildContext context) {
    final arquivos = context.watch<ArquivosNavi>();
    final rosto = enquadramento == Enquadramento.rosto;

    final Widget conteudo;
    if (rosto) {
      final retrato = arquivos.retrato;
      conteudo = SizedBox(
        width: largura,
        height: altura,
        child: retrato == null
            ? const _RostoVazio()
            : Image.memory(
                retrato,
                fit: BoxFit.cover,
                alignment: alinhamento,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
      );
    } else if (arquivos.modelo != null && Navi3D.suportado) {
      conteudo = SizedBox(
        width: largura,
        height: altura,
        child: Navi3D(
          enquadramento: enquadramento == Enquadramento.busto
              ? Enquadramento3D.busto
              : Enquadramento3D.corpo,
          humor: humor,
          falando: falando,
          reserva: const SizedBox.shrink(), // só a barra de progresso
        ),
      );
    } else {
      conteudo = SizedBox(
        width: largura,
        height: altura,
        child: _SemModelo(temModelo: arquivos.modelo != null),
      );
    }

    if (redondo) return ClipOval(child: conteudo);
    if (raio != null) return ClipRRect(borderRadius: raio!, child: conteudo);
    return conteudo;
  }
}

/// Foto pequena antes de existir um retrato do modelo.
class _RostoVazio extends StatelessWidget {
  const _RostoVazio();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Cores.roxoFundo,
      child: LayoutBuilder(
        builder: (context, limites) => Icon(
          Icons.face_retouching_natural_outlined,
          color: Cores.roxoBorda,
          size: limites.biggest.shortestSide * 0.5,
        ),
      ),
    );
  }
}

/// Palco sem modelo 3D: toque abre a importação.
class _SemModelo extends StatelessWidget {
  /// Há modelo, mas esta plataforma não mostra 3D.
  final bool temModelo;
  const _SemModelo({required this.temModelo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: temModelo
            ? null
            : () => Navigator.of(context).pushNamed(Rotas.importar),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_in_ar_outlined,
                size: 40,
                color: Cores.roxoBorda,
              ),
              const SizedBox(height: 8),
              Text(
                temModelo ? 'o 3D não aparece aqui' : 'nenhum modelo 3D',
                style: const TextStyle(color: Cores.textoApagado, fontSize: 12),
              ),
              if (!temModelo)
                const Text(
                  'toque para importar um .vrm',
                  style: TextStyle(color: Cores.textoFraco, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
