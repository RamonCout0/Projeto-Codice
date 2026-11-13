import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/tema/imagens.dart';
import 'package:codice_app/widgets/navi_3d.dart';

enum Enquadramento { corpo, busto, rosto }

/// O único lugar do app que desenha a NAVI.
/// - corpo/busto: o modelo 3D animado, quando um .vrm foi importado;
/// - rosto: a foto tirada do próprio modelo.
/// Sem modelo (ou no PC), cai nas imagens estáticas da Frost.
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

    final ImageProvider imagem = rosto
        ? (arquivos.retrato != null
              ? MemoryImage(arquivos.retrato!)
              : Imagens.frostRosto)
        : Imagens.frostCorpo;
    final estatica = Image(
      image: imagem,
      width: largura,
      height: altura,
      fit: rosto || redondo || raio != null ? BoxFit.cover : BoxFit.contain,
      alignment: alinhamento,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );

    Widget conteudo = estatica;
    if (!rosto && arquivos.modelo != null && Navi3D.suportado) {
      conteudo = SizedBox(
        width: largura,
        height: altura,
        child: Navi3D(
          enquadramento: enquadramento == Enquadramento.busto
              ? Enquadramento3D.busto
              : Enquadramento3D.corpo,
          humor: humor,
          falando: falando,
          reserva: estatica,
        ),
      );
    }

    if (redondo) return ClipOval(child: conteudo);
    if (raio != null) return ClipRRect(borderRadius: raio!, child: conteudo);
    return conteudo;
  }
}
