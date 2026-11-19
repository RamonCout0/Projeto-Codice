import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/widgets/navi_3d/visualizador.dart';

enum Enquadramento3D { corpo, busto }

/// A NAVI em 3D, animada. Por dentro é uma página three.js + three-vrm
/// (veja navi_3d/src): WebView no celular e iframe na web. Só aparece
/// quando há um modelo (importado ou em assets/navi_local); fora disso o
/// [AvatarNavi] usa a imagem.
class Navi3D extends StatefulWidget {
  final Enquadramento3D enquadramento;
  final Humor humor;
  final bool falando;

  /// Mostrado enquanto o modelo carrega ou se der erro.
  final Widget reserva;

  const Navi3D({
    super.key,
    required this.reserva,
    this.enquadramento = Enquadramento3D.corpo,
    this.humor = Humor.esperando,
    this.falando = false,
  });

  static bool get suportado => Visualizador.suportado;

  @override
  State<Navi3D> createState() => _Navi3DState();
}

class _Navi3DState extends State<Navi3D> {
  late final ArquivosNavi _arquivos = context.read<ArquivosNavi>();
  late final Visualizador _visualizador = Visualizador(_aoReceber);
  int _versaoCarregada = -1;
  FonteNavi? _modeloCarregado;
  bool _pronto = false;
  double _progresso = 0;
  bool _visivel = true;

  @override
  void initState() {
    super.initState();
    _arquivos.addListener(_aoMudarArquivos);
    _carregar();
  }

  @override
  void dispose() {
    _arquivos.removeListener(_aoMudarArquivos);
    _visualizador.descartar();
    super.dispose();
  }

  void _aoMudarArquivos() {
    if (_arquivos.versao != _versaoCarregada ||
        _arquivos.modelo != _modeloCarregado) {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    _versaoCarregada = _arquivos.versao;
    _modeloCarregado = _arquivos.modelo;
    setState(() {
      _pronto = false;
      _progresso = 0;
    });
    if (_arquivos.modelo == null) return;

    await _visualizador.abrir(_arquivos, {
      'enquadramento': widget.enquadramento.name,
      if (_arquivos.retrato == null) 'retrato': '1',
      'v': '$_versaoCarregada', // evita o cache do modelo anterior
    });
    if (mounted) setState(() {});
  }

  void _aoReceber(Map<String, dynamic> dados) {
    if (!mounted) return;
    switch (dados['tipo']) {
      case 'progresso':
        setState(() => _progresso = (dados['valor'] as num).toDouble());
      case 'retrato':
        _arquivos.salvarRetrato(base64Decode(dados['png'] as String));
      case 'pronto':
        setState(() => _pronto = true);
        _enviarEstado();
      case 'erro':
        debugPrint('[Navi3D] ${dados['mensagem']}');
    }
  }

  void _enviarEstado() {
    _visualizador.comando('humor', widget.humor.name);
    _visualizador.comando('falar', widget.falando);
    _visualizador.comando('pausar', !_visivel);
  }

  @override
  void didUpdateWidget(Navi3D antigo) {
    super.didUpdateWidget(antigo);
    if (!_pronto) return;
    if (antigo.humor != widget.humor) {
      _visualizador.comando('humor', widget.humor.name);
    }
    if (antigo.falando != widget.falando) {
      _visualizador.comando('falar', widget.falando);
    }
  }

  /// Aba escondida no IndexedStack: para de desenhar e poupa bateria.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visivel = Visibility.of(context);
    if (visivel == _visivel) return;
    _visivel = visivel;
    if (_pronto) _visualizador.comando('pausar', !visivel);
  }

  @override
  Widget build(BuildContext context) {
    final temModelo = _arquivos.modelo != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // O visualizador fica sempre desenhado (com opacidade 0 o Flutter
        // nem coloca o iframe/WebView na tela, e ele nunca carregaria).
        // A imagem de reserva fica por cima e some quando a NAVI fica pronta.
        if (temModelo) _visualizador.construir(),
        IgnorePointer(
          ignoring: _pronto,
          child: AnimatedOpacity(
            opacity: _pronto ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: widget.reserva,
          ),
        ),
        if (!_pronto && temModelo)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LinearProgressIndicator(
                value: _progresso == 0 ? null : _progresso,
                minHeight: 3,
                color: Cores.roxo,
              ),
            ),
          ),
      ],
    );
  }
}
