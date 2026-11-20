import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/avatar_navi.dart';
import 'package:codice_app/widgets/basicos.dart';

const _raioBalao = Radius.circular(15);

/// Mensagem da NAVI, com o rosto dela ao lado.
class BalaoNavi extends StatelessWidget {
  final String texto;

  const BalaoNavi(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarNavi(largura: 36, altura: 44, raio: BorderRadius.circular(10)),
        const SizedBox(width: 8),
        Flexible(
          child: Painel(
            raio: const BorderRadius.only(
              topLeft: _raioBalao,
              topRight: _raioBalao,
              bottomRight: _raioBalao,
            ),
            child: Text(texto, style: Estilos.corpo),
          ),
        ),
      ],
    );
  }
}

class BalaoUsuario extends StatelessWidget {
  final String texto;

  const BalaoUsuario(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Painel(
          cor: Cores.roxoAtivo,
          borda: Cores.bordaRoxa,
          raio: const BorderRadius.only(
            topLeft: _raioBalao,
            topRight: _raioBalao,
            bottomLeft: _raioBalao,
          ),
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rodapé fixo: campo de texto + botão de enviar.
class CampoMensagem extends StatelessWidget {
  final TextEditingController controle;
  final bool habilitado;
  final VoidCallback aoEnviar;

  const CampoMensagem({
    super.key,
    required this.controle,
    required this.habilitado,
    required this.aoEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: Cores.borda),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controle,
              style: Estilos.corpo,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => aoEnviar(),
              decoration: InputDecoration(
                hintText:
                    'escrever para ${context.watch<Sessao>().perfil.nome}...',
                hintStyle: const TextStyle(color: Color(0xFF898394)),
                filled: true,
                fillColor: const Color(0xFF171620),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: borda,
                enabledBorder: borda,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'enviar',
            onPressed: habilitado ? aoEnviar : null,
            iconSize: 22,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(50),
              backgroundColor: Cores.roxo,
              foregroundColor: Cores.sobreRoxo,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
