import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/cabecalhos.dart';
import 'package:codice_app/models/ajustes.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  Widget _chave(
    String titulo,
    String subtitulo,
    bool valor,
    ValueChanged<bool> mudar,
  ) {
    return SwitchListTile(
      value: valor,
      activeThumbColor: kPurple,
      title: Text(
        titulo,
        style: const TextStyle(color: Color(0xFFE4E0E9), fontSize: 13),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(color: Color(0xFF8B8498), fontSize: 10),
      ),
      onChanged: (v) {
        debugPrint('[Configurações] $titulo: $v');
        setState(() => mudar(v));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabecalhoDetalhe('Configurações'),
            const TituloGrande(
              'Configurações',
              subtitulo: 'só ficam guardadas enquanto o app está aberto.',
            ),
            const SizedBox(height: 14),
            _chave(
              'Falas em Navidês',
              'tocar os bipes quando a Frost conversa com outro NAVI',
              Ajustes.falasEmNavides,
              (v) => Ajustes.falasEmNavides = v,
            ),
            _chave(
              'Avisar encontros',
              'notificar quando um NAVI for encontrado por Bluetooth',
              Ajustes.avisarEncontros,
              (v) => Ajustes.avisarEncontros = v,
            ),
            _chave(
              'Relato da cidade',
              'resumo do que a Frost fez na NAVICity enquanto você saiu',
              Ajustes.relatoDaCidade,
              (v) => Ajustes.relatoDaCidade = v,
            ),
          ],
        ),
      ),
    );
  }
}
