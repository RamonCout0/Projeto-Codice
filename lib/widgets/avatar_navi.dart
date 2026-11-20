import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/widgets/navi_3d.dart';
import 'package:codice_app/widgets/navi_vetor.dart';

enum Enquadramento { corpo, busto, rosto }

/// O único lugar do app que desenha a NAVI.
/// - corpo/busto: o modelo 3D animado (importado ou em assets/navi_local);
/// - rosto: a foto tirada do próprio modelo depois que ele carrega.
/// Sem modelo 3D (ou onde o 3D não roda), mostra a NAVI vetorial do projeto,
/// com o humor e as cores do elemento.
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
    final cor = context.watch<Sessao>().perfil.elemento.cor;
    final rosto = enquadramento == Enquadramento.rosto;

    final Widget conteudo;
    if (rosto) {
      final retrato = arquivos.retrato;
      conteudo = SizedBox(
        width: largura,
        height: altura,
        child: retrato == null
            ? LayoutBuilder(
                builder: (context, lim) => RostoVetor(
                  cor: cor,
                  humor: humor,
                  tamanho: lim.biggest.shortestSide.isFinite ? lim.biggest.shortestSide : 48,
                ),
              )
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
        child: LayoutBuilder(
          builder: (context, lim) {
            final h = lim.hasBoundedHeight ? lim.maxHeight : 260.0;
            final w = lim.hasBoundedWidth ? lim.maxWidth : h;
            // Cabe no espaço mantendo a proporção 200:240 do desenho.
            final altNavi = (h * 0.96).clamp(0.0, w * 1.2 * 0.96);
            return Align(
              alignment: alinhamento == Alignment.center ? Alignment.bottomCenter : alinhamento,
              child: NaviVetor(cor: cor, humor: humor, altura: altNavi),
            );
          },
        ),
      );
    }

    if (redondo) return ClipOval(child: conteudo);
    if (raio != null) return ClipRRect(borderRadius: raio!, child: conteudo);
    return conteudo;
  }
}
