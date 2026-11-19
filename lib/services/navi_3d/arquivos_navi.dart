import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Animações prontas (.vrma ou .fbx do Mixamo) que a NAVI sabe usar.
enum Gesto {
  parada('Parada', 'repete o tempo todo'),
  aceno('Aceno', 'quando você toca nela'),
  comemorar('Comemorar', 'quando ela fica feliz');

  final String titulo;
  final String quando;
  const Gesto(this.titulo, this.quando);
}

/// Onde está um arquivo da NAVI (modelo ou animação).
sealed class FonteNavi {
  const FonteNavi(this.extensao);

  /// vrm, vrma ou fbx: diz ao visualizador como ler o arquivo.
  final String extensao;
}

/// Importado no celular: copiado para a pasta do app.
class FonteArquivo extends FonteNavi {
  const FonteArquivo(this.arquivo, super.extensao);
  final File arquivo;
}

/// Importado no navegador: fica na memória enquanto a aba está aberta.
class FonteBytes extends FonteNavi {
  const FonteBytes(this.bytes, super.extensao);
  final Uint8List bytes;
}

/// Colocado em assets/navi_local/ e embutido no app na hora do build.
class FonteAsset extends FonteNavi {
  const FonteAsset(this.chave, super.extensao);
  final String chave;
}

/// Modelo .vrm e animações (.vrma/.fbx) da NAVI.
///
/// Vêm de dois lugares, nesta ordem de prioridade:
/// 1. importados pela pessoa na tela "Importar NAVI";
/// 2. a pasta assets/navi_local/ do projeto (bom para apresentar na web,
///    onde o `flutter run -d edge` abre um navegador limpo toda vez).
///
/// Nada disso vai para o repositório: cada modelo tem a sua licença.
class ArquivosNavi extends ChangeNotifier {
  static const pastaLocal = 'assets/navi_local/';

  Directory? _pasta;
  FonteNavi? _modeloImportado;
  FonteNavi? _modeloEmbutido;
  String? _nomeImportado;
  String? _nomeEmbutido;
  Uint8List? _retrato;
  final Map<Gesto, FonteNavi> _animImportadas = {};
  final Map<Gesto, FonteNavi> _animEmbutidas = {};

  /// Muda a cada importação: o visualizador 3D recarrega quando ela muda.
  int versao = 0;

  FonteNavi? get modelo => _modeloImportado ?? _modeloEmbutido;
  String? get nomeModelo =>
      _modeloImportado != null ? _nomeImportado : _nomeEmbutido;
  bool get modeloImportado => _modeloImportado != null;
  bool get modeloEmbutido => _modeloImportado == null && _modeloEmbutido != null;
  Uint8List? get retrato => _retrato;

  Map<Gesto, FonteNavi> get animacoes =>
      Map.unmodifiable({..._animEmbutidas, ..._animImportadas});
  bool animacaoImportada(Gesto g) => _animImportadas.containsKey(g);

  File _arquivo(String nome) => File('${_pasta!.path}/$nome');
  static String _nomeAnimacao(Gesto g, String extensao) =>
      'anim_${g.name}.$extensao';
  static const _extensoesAnimacao = ['vrma', 'fbx'];

  Future<void> carregar() async {
    await _carregarEmbutidos();
    await _carregarImportados();
    notifyListeners();
  }

  /// Procura modelo.vrm (ou outro .vrm) e parada/aceno/comemorar.(vrma|fbx)
  /// em assets/navi_local/.
  Future<void> _carregarEmbutidos() async {
    try {
      final manifesto = await AssetManifest.loadFromAssetBundle(rootBundle);
      final locais = manifesto
          .listAssets()
          .where((a) => a.startsWith(pastaLocal))
          .toList();
      final vrms = locais.where((a) => a.toLowerCase().endsWith('.vrm'));
      final chave = vrms.contains('${pastaLocal}modelo.vrm')
          ? '${pastaLocal}modelo.vrm'
          : vrms.firstOrNull;
      if (chave != null) {
        _modeloEmbutido = FonteAsset(chave, 'vrm');
        final dados = await rootBundle.load(chave);
        _nomeEmbutido = lerGlbBytes(dados.buffer.asUint8List())?.nomeModelo;
      }
      for (final g in Gesto.values) {
        for (final ext in _extensoesAnimacao) {
          final a = '$pastaLocal${g.name}.$ext';
          if (locais.contains(a)) _animEmbutidas[g] = FonteAsset(a, ext);
        }
      }
    } catch (_) {
      // Sem manifesto (alguns testes): segue sem os embutidos.
    }
  }

  Future<void> _carregarImportados() async {
    if (kIsWeb) return; // na web o que foi importado não sobrevive à aba
    try {
      final docs = await getApplicationDocumentsDirectory();
      _pasta = await Directory('${docs.path}/navi').create(recursive: true);
    } catch (_) {
      return; // sem pasta (ex.: testes): segue só com as imagens estáticas
    }
    final modelo = _arquivo('modelo.vrm');
    if (await modelo.exists()) {
      _modeloImportado = FonteArquivo(modelo, 'vrm');
      _nomeImportado = (await lerGlb(modelo))?.nomeModelo;
      final retrato = _arquivo('retrato.png');
      if (await retrato.exists()) _retrato = await retrato.readAsBytes();
    }
    for (final g in Gesto.values) {
      for (final ext in _extensoesAnimacao) {
        final f = _arquivo(_nomeAnimacao(g, ext));
        if (await f.exists()) _animImportadas[g] = FonteArquivo(f, ext);
      }
    }
  }

  /// Abre o seletor de arquivos. Retorna uma mensagem de erro, ou null.
  Future<String?> importarModelo() async {
    final escolhido = await _escolher();
    if (escolhido == null) return null;
    final info = lerGlbBytes(escolhido.cabecalho);
    if (info == null || !info.ehModelo) {
      return 'esse arquivo não é um modelo .vrm';
    }
    _modeloImportado = await _guardar(escolhido, 'modelo.vrm', 'vrm');
    _nomeImportado = info.nomeModelo;
    await _apagarRetrato(); // o próximo carregamento tira uma foto nova
    _mudou();
    return null;
  }

  Future<String?> importarAnimacao(Gesto gesto) async {
    final escolhido = await _escolher();
    if (escolhido == null) return null;
    final String extensao;
    if (ehFbxBytes(escolhido.cabecalho)) {
      extensao = 'fbx'; // o visualizador converte do esqueleto do Mixamo
    } else if (lerGlbBytes(escolhido.cabecalho)?.ehAnimacao ?? false) {
      extensao = 'vrma';
    } else {
      return 'esse arquivo não é uma animação .vrma nem .fbx do Mixamo';
    }
    await _apagarAnimacao(gesto); // pode existir uma no outro formato
    _animImportadas[gesto] = await _guardar(
      escolhido,
      _nomeAnimacao(gesto, extensao),
      extensao,
    );
    _mudou();
    return null;
  }

  /// Remove o importado. Se houver um em assets/navi_local, ele volta.
  Future<void> removerModelo() async {
    final f = _modeloImportado;
    if (f is FonteArquivo && await f.arquivo.exists()) await f.arquivo.delete();
    _modeloImportado = null;
    _nomeImportado = null;
    await _apagarRetrato();
    _mudou();
  }

  Future<void> removerAnimacao(Gesto gesto) async {
    await _apagarAnimacao(gesto);
    _mudou();
  }

  Future<void> _apagarAnimacao(Gesto gesto) async {
    final f = _animImportadas.remove(gesto);
    if (f is FonteArquivo && await f.arquivo.exists()) await f.arquivo.delete();
  }

  /// Foto do rosto gerada pelo visualizador 3D. Só fica salva para o
  /// modelo importado no celular; nos outros casos é tirada a cada abertura.
  Future<void> salvarRetrato(Uint8List png) async {
    _retrato = png;
    notifyListeners();
    if (_pasta != null && _modeloImportado is FonteArquivo) {
      await _arquivo('retrato.png').writeAsBytes(png);
    }
  }

  Future<void> _apagarRetrato() async {
    _retrato = null;
    if (_pasta == null) return;
    final f = _arquivo('retrato.png');
    if (await f.exists()) await f.delete();
  }

  void _mudou() {
    versao++;
    notifyListeners();
  }

  Future<FonteNavi> _guardar(_Escolhido e, String nome, String ext) async {
    if (kIsWeb || _pasta == null || e.arquivo == null) {
      return FonteBytes(e.bytes ?? await e.arquivo!.readAsBytes(), ext);
    }
    return FonteArquivo(await e.arquivo!.copy(_arquivo(nome).path), ext);
  }

  Future<_Escolhido?> _escolher() async {
    if (!kIsWeb && _pasta == null) return null;
    final escolhido = await FilePicker.pickFile();
    if (escolhido == null) return null;
    final caminho = escolhido.path;
    if (!kIsWeb && caminho != null) {
      final arquivo = File(caminho);
      return _Escolhido(arquivo: arquivo, cabecalho: await _inicio(arquivo));
    }
    final bytes = await escolhido.readAsBytes();
    return _Escolhido(bytes: bytes, cabecalho: bytes);
  }

  /// Começo do arquivo: o bastante para o cabeçalho JSON do glTF.
  static Future<Uint8List> _inicio(File arquivo) async {
    final leitor = await arquivo.open();
    try {
      final topo = await leitor.read(20);
      if (topo.length < 20) return topo;
      // Num .fbx esse campo é lixo: o limite evita ler o arquivo inteiro.
      final tamanho = ByteData.sublistView(topo).getUint32(12, Endian.little);
      await leitor.setPosition(0);
      return await leitor.read(20 + (tamanho < 1 << 22 ? tamanho : 0));
    } finally {
      await leitor.close();
    }
  }
}

class _Escolhido {
  _Escolhido({this.arquivo, this.bytes, required this.cabecalho});
  final File? arquivo;
  final Uint8List? bytes;
  final Uint8List cabecalho;
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

/// Lê o bloco JSON do início de um glTF binário já em memória.
InfoGlb? lerGlbBytes(Uint8List dados) {
  try {
    if (dados.length < 20) return null;
    final cabecalho = ByteData.sublistView(dados, 0, 20);
    final magico = cabecalho.getUint32(0, Endian.little);
    final tipoBloco = cabecalho.getUint32(16, Endian.little);
    if (magico != 0x46546C67 || tipoBloco != 0x4E4F534A) {
      return null; // glTF / JSON
    }
    final tamanho = cabecalho.getUint32(12, Endian.little);
    final json = jsonDecode(utf8.decode(dados.sublist(20, 20 + tamanho)));
    return InfoGlb((json as Map).cast<String, dynamic>());
  } catch (_) {
    return null;
  }
}

/// Lê só o bloco JSON do início do arquivo, sem carregar os megabytes
/// de malha e textura.
Future<InfoGlb?> lerGlb(File arquivo) async {
  try {
    return lerGlbBytes(await ArquivosNavi._inicio(arquivo));
  } catch (_) {
    return null;
  }
}

/// FBX binário ("Kaydara FBX Binary") ou texto ("; FBX ..."), como o
/// Mixamo exporta.
bool ehFbxBytes(Uint8List dados) {
  final inicio = latin1.decode(
    dados.sublist(0, dados.length < 32 ? dados.length : 32),
    allowInvalid: true,
  );
  return inicio.startsWith('Kaydara FBX Binary') ||
      inicio.trimLeft().startsWith('; FBX');
}

Future<bool> ehFbx(File arquivo) async {
  try {
    return ehFbxBytes(await ArquivosNavi._inicio(arquivo));
  } catch (_) {
    return false;
  }
}
