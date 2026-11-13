import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:codice_app/models/humor.dart';
import 'package:codice_app/services/navi_3d/arquivos_navi.dart';
import 'package:codice_app/services/navi_3d/servidor_navi.dart';
import 'package:codice_app/tema/cores.dart';

enum Enquadramento3D { corpo, busto }

/// A NAVI em 3D, animada. Por dentro é uma WebView rodando three.js +
/// three-vrm (veja navi_3d/src). Só existe no Android e no iOS e só
/// quando um modelo foi importado; fora disso o [AvatarNavi] usa a imagem.
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

  static bool get suportado =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  State<Navi3D> createState() => _Navi3DState();
}

class _Navi3DState extends State<Navi3D> {
  late final ArquivosNavi _arquivos = context.read<ArquivosNavi>();
  WebViewController? _controle;
  int _versaoCarregada = -1;
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
    super.dispose();
  }

  void _aoMudarArquivos() {
    if (_arquivos.versao != _versaoCarregada) _carregar();
  }

  Future<void> _carregar() async {
    _versaoCarregada = _arquivos.versao;
    setState(() {
      _pronto = false;
      _progresso = 0;
    });
    if (_arquivos.modelo == null) return;

    final base = await ServidorNavi.endereco(_arquivos);
    final endereco = base.replace(
      queryParameters: {
        'enquadramento': widget.enquadramento.name,
        if (_arquivos.retrato == null) 'retrato': '1',
        'v': '$_versaoCarregada', // evita o cache do modelo anterior
      },
    );
    final controle = _controle ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('Navi', onMessageReceived: _aoReceber);
    await controle.loadRequest(endereco);
    if (mounted) setState(() {});
  }

  void _aoReceber(JavaScriptMessage mensagem) {
    final dados = jsonDecode(mensagem.message) as Map<String, dynamic>;
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

  void _js(String codigo) => _controle?.runJavaScript('window.navi?.$codigo');

  void _enviarEstado() {
    _js("humor('${widget.humor.name}')");
    _js('falar(${widget.falando})');
    _js('pausar(${!_visivel})');
  }

  @override
  void didUpdateWidget(Navi3D antigo) {
    super.didUpdateWidget(antigo);
    if (!_pronto) return;
    if (antigo.humor != widget.humor) _js("humor('${widget.humor.name}')");
    if (antigo.falando != widget.falando) _js('falar(${widget.falando})');
  }

  /// Aba escondida no IndexedStack: para de desenhar e poupa bateria.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visivel = Visibility.of(context);
    if (visivel == _visivel) return;
    _visivel = visivel;
    if (_pronto) _js('pausar(${!visivel})');
  }

  @override
  Widget build(BuildContext context) {
    final controle = _controle;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_pronto) widget.reserva,
        if (controle != null && _arquivos.modelo != null)
          AnimatedOpacity(
            opacity: _pronto ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: WebViewWidget(controller: controle),
          ),
        if (!_pronto && _arquivos.modelo != null)
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
