import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Animações prontas (.vrma) que a NAVI sabe usar.
enum Gesto {
  parada('Parada', 'repete o tempo todo'),
  aceno('Aceno', 'quando você toca nela'),
  comemorar('Comemorar', 'quando ela fica feliz');

  final String titulo;
  final String quando;
  const Gesto(this.titulo, this.quando);
}

/// Modelo .vrm e animações .vrma importados pela pessoa. Ficam na pasta
/// do app no aparelho: nada disso vai para o repositório, porque cada
/// modelo tem a sua licença.
class ArquivosNavi extends ChangeNotifier {
  Directory? _pasta;
  File? _modelo;
  String? _nomeModelo;
  Uint8List? _retrato;
  final Map<Gesto, File> _animacoes = {};

  /// Muda a cada importação: o visualizador 3D recarrega quando ela muda.
  int versao = 0;

  File? get modelo => _modelo;
  String? get nomeModelo => _nomeModelo;
  Uint8List? get retrato => _retrato;
  Map<Gesto, File> get animacoes => Map.unmodifiable(_animacoes);

  File _arquivo(String nome) => File('${_pasta!.path}/$nome');
  static String _nomeAnimacao(Gesto g) => 'anim_${g.name}.vrma';

  Future<void> carregar() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _pasta = await Directory('${docs.path}/navi').create(recursive: true);
    } catch (_) {
      return; // sem pasta (ex.: testes): segue só com as imagens estáticas
    }
    final modelo = _arquivo('modelo.vrm');
    if (await modelo.exists()) {
      _modelo = modelo;
      _nomeModelo = (await lerGlb(modelo))?.nomeModelo;
    }
    final retrato = _arquivo('retrato.png');
    if (await retrato.exists()) _retrato = await retrato.readAsBytes();
    for (final g in Gesto.values) {
      final f = _arquivo(_nomeAnimacao(g));
      if (await f.exists()) _animacoes[g] = f;
    }
    notifyListeners();
  }

  /// Abre o seletor de arquivos. Retorna uma mensagem de erro, ou null.
  Future<String?> importarModelo() async {
    final origem = await _escolher();
    if (origem == null) return null;
    final info = await lerGlb(origem);
    if (info == null || !info.ehModelo) {
      return 'esse arquivo não é um modelo .vrm';
    }
    _modelo = await origem.copy(_arquivo('modelo.vrm').path);
    _nomeModelo = info.nomeModelo;
    await _apagarRetrato(); // o próximo carregamento tira uma foto nova
    _mudou();
    return null;
  }

  Future<String?> importarAnimacao(Gesto gesto) async {
    final origem = await _escolher();
    if (origem == null) return null;
    final info = await lerGlb(origem);
    if (info == null || !info.ehAnimacao) {
      return 'esse arquivo não é uma animação .vrma';
    }
    _animacoes[gesto] = await origem.copy(_arquivo(_nomeAnimacao(gesto)).path);
    _mudou();
    return null;
  }

  Future<void> removerModelo() async {
    await _modelo?.delete();
    _modelo = null;
    _nomeModelo = null;
    await _apagarRetrato();
    _mudou();
  }

  Future<void> removerAnimacao(Gesto gesto) async {
    await _animacoes.remove(gesto)?.delete();
    _mudou();
  }

  /// Foto do rosto gerada pelo visualizador 3D.
  Future<void> salvarRetrato(Uint8List png) async {
    _retrato = png;
    notifyListeners();
    await _arquivo('retrato.png').writeAsBytes(png);
  }

  Future<void> _apagarRetrato() async {
    _retrato = null;
    final f = _arquivo('retrato.png');
    if (await f.exists()) await f.delete();
  }

  void _mudou() {
    versao++;
    notifyListeners();
  }

  Future<File?> _escolher() async {
    if (_pasta == null) return null;
    final escolhido = await FilePicker.pickFile();
    final caminho = escolhido?.path;
    return caminho == null ? null : File(caminho);
  }
}

/// O que interessa do cabeçalho de um arquivo glTF binário (.vrm/.vrma).
class InfoGlb {
  final Map<String, dynamic> json;
  InfoGlb(this.json);

  Map<String, dynamic> get _ext =>
      (json['extensions'] as Map?)?.cast<String, dynamic>() ?? {};

  bool get ehModelo => _ext.containsKey('VRMC_vrm') || _ext.containsKey('VRM');
  bool get ehAnimacao => _ext.containsKey('VRMC_vrm_animation');

  String? get nomeModelo {
    final vrm1 = _ext['VRMC_vrm']?['meta']?['name'];
    final vrm0 = _ext['VRM']?['meta']?['title'];
    return (vrm1 ?? vrm0) as String?;
  }
}

/// Lê só o bloco JSON do início do arquivo, sem carregar os megabytes
/// de malha e textura.
Future<InfoGlb?> lerGlb(File arquivo) async {
  RandomAccessFile? leitor;
  try {
    leitor = await arquivo.open();
    final cabecalho = ByteData.sublistView(await leitor.read(20));
    final magico = cabecalho.getUint32(0, Endian.little);
    final tipoBloco = cabecalho.getUint32(16, Endian.little);
    if (magico != 0x46546C67 || tipoBloco != 0x4E4F534A)
      return null; // glTF / JSON
    final tamanho = cabecalho.getUint32(12, Endian.little);
    final json = jsonDecode(utf8.decode(await leitor.read(tamanho)));
    return InfoGlb((json as Map).cast<String, dynamic>());
  } catch (_) {
    return null;
  } finally {
    await leitor?.close();
  }
}
