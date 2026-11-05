import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'frost_assets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => EstadoCodice(),
      child: const CodiceApp(),
    ),
  );
}

class CodiceApp extends StatefulWidget {
  const CodiceApp({super.key});

  @override
  State<CodiceApp> createState() => _CodiceAppState();
}

class _CodiceAppState extends State<CodiceApp> {
  /// Imprime no console cada push/pop da pilha raiz (login, app,
  /// configurações e diálogos).
  final ObservadorDaPilha _observadorRaiz = ObservadorDaPilha('raiz');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Códice',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPurple,
          brightness: Brightness.dark,
        ),
      ),
      // A moldura embrulha o Navigator inteiro: assim a troca de tela,
      // os AlertDialogs, as SnackBars e o bottom sheet acontecem DENTRO
      // do "celular", em vez de escaparem para a janela toda.
      builder: (context, child) => PhoneFrame(child: child!),
      // Rotas nomeadas centralizadas: as telas sem parâmetro ficam no
      // mapa; as que recebem arguments passam pelo Rotas.gerar.
      initialRoute: Rotas.login,
      routes: Rotas.mapa,
      onGenerateRoute: Rotas.gerar,
      navigatorObservers: [_observadorRaiz],
    );
  }
}

// ============================================================
// ROTAS NOMEADAS (tudo num lugar só)
//
// Pilha raiz (Navigator do MaterialApp):
//   /                login. O logout volta para cá com pushReplacement.
//   /app             AppShell: Drawer + BottomNavigationBar.
//   /configuracoes   push por cima do app inteiro (a barra some).
//
// Pilha de cada aba (Navigator aninhado do AppShell):
//   /navi  /conversa  /diario  /cidade  /encontros   raízes das abas
//   /cidade/lugar       recebe um Lugar via arguments
//   /encontros/navi     recebe um NaviEncontrado via arguments
//   /encontros/apelido  recebe o apelido atual e DEVOLVE o novo no pop
// ============================================================

class Rotas {
  Rotas._();

  static const String login = '/';
  static const String app = '/app';
  static const String configuracoes = '/configuracoes';

  static const String navi = '/navi';
  static const String conversa = '/conversa';
  static const String diario = '/diario';
  static const String cidade = '/cidade';
  static const String lugar = '/cidade/lugar';
  static const String encontros = '/encontros';
  static const String naviEncontrado = '/encontros/navi';
  static const String apelido = '/encontros/apelido';

  /// Mapa entregue ao MaterialApp.routes.
  static final Map<String, WidgetBuilder> mapa = {
    login: (_) => const WelcomeScreen(),
    app: (_) => const AppShell(),
    configuracoes: (_) => const ConfiguracoesScreen(),
  };

  /// Usado pelo MaterialApp.onGenerateRoute e pelos Navigators de cada
  /// aba. É aqui que os arguments viram parâmetros das telas.
  static Route<dynamic>? gerar(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case navi:
        return _pagina(settings, const HomeScreen());
      case conversa:
        return _pagina(settings, const ConversationScreen());
      case diario:
        return _pagina(settings, const DiaryScreen());
      case cidade:
        return _pagina(settings, const CityScreen());
      case lugar:
        return _pagina(settings, LugarScreen(lugar: args as Lugar));
      case encontros:
        return _pagina(settings, const MeetingsScreen());
      case naviEncontrado:
        return _pagina(settings, NaviScreen(navi: args as NaviEncontrado));
      case apelido:
        // Tipada como <String>: quem chama faz pushNamed<String> e
        // recebe o apelido de volta. Uma MaterialPageRoute<dynamic>
        // aqui quebraria o cast dentro do pushNamed<String>.
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (_) => ApelidoScreen(apelidoAtual: args as String),
        );
    }
    return null;
  }

  static MaterialPageRoute<void> _pagina(RouteSettings s, Widget tela) =>
      MaterialPageRoute<void>(settings: s, builder: (_) => tela);
}

// ============================================================
// LOG DA PILHA (debugPrint de cada push/pop)
// ============================================================

/// Um observador por Navigator: ele guarda uma cópia da pilha e imprime
/// como ela ficou depois de cada operação.
class ObservadorDaPilha extends NavigatorObserver {
  final String nome;
  final List<Route<dynamic>> _rotas = [];

  ObservadorDaPilha(this.nome);

  String _nomeDe(Route<dynamic> r) =>
      r.settings.name ?? (r is PopupRoute ? '(diálogo)' : '(sem nome)');

  /// Ex.: "/encontros > /encontros/navi"
  String get pilha => _rotas.map(_nomeDe).join(' > ');

  int get tamanho => _rotas.length;

  void _log(String operacao, Route<dynamic> r) {
    debugPrint('[pilha $nome] $operacao ${_nomeDe(r)}  =>  [$pilha]');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.add(route);
    _log('PUSH', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.remove(route);
    _log('POP ', route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _rotas.remove(route);
    _log('REMOVE', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _rotas.indexOf(oldRoute);
    if (newRoute == null) return;
    if (i >= 0) {
      _rotas[i] = newRoute;
    } else {
      _rotas.add(newRoute);
    }
    _log('REPLACE ${oldRoute == null ? '' : _nomeDe(oldRoute)} ->',
        newRoute);
  }
}

// ============================================================
// CORES
// ============================================================

const Color kBg = Color(0xFF0E0D15);
const Color kBottom = Color(0xFF12101B);
const Color kPanel = Color(0xFF171521);
const Color kPurple = Color(0xFF9B82FF);
const Color kPurple2 = Color(0xFFAA91FF);
const Color kLine = Color(0xFF302B3C);

// ============================================================
// IMAGEM ÚNICA DA NAVI FROST
//
// PNG recortado nas bordas transparentes e sem a sombra que vinha
// "assada" no render — o chão agora é desenhado pelo próprio app.
//
// A imagem está incorporada em Base64 (sem assets externos), no
// arquivo frost_assets.dart.
// Todas as telas usam esta mesma imagem.
// ============================================================


// Antes era um getter: cada rebuild decodificava de novo os ~380 KB e
// entregava ao Image.memory uma lista de bytes NOVA. O cache de imagens
// do Flutter compara pela instância, então tratava como imagem diferente
// e recarregava — por isso a Frost piscava/sumia a cada setState.
// Variável global final é calculada uma vez só (e só quando usada).
final Uint8List naviFrostBytes =
    base64Decode(naviFrostBase64.replaceAll(RegExp(r'\s+'), ''));

/// Mesma instância em todas as telas = uma decodificação, um cache.
final MemoryImage frostImage = MemoryImage(naviFrostBytes);


final MemoryImage frostRostoImage = MemoryImage(
  base64Decode(naviFrostRostoBase64.replaceAll(RegExp(r'\s+'), '')),
);

// ============================================================
// MOLDURA DO CELULAR
// ============================================================

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  static const Size tamanho = Size(338, 777);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Celular de verdade (tela estreita): a moldura não faz sentido,
        // o app ocupa a tela inteira.
        if (constraints.maxWidth < 500) return child;

        // PC/projetor: desenha o "celular" e encolhe se a janela for
        // baixa, em vez de estourar a altura.
        final midia = MediaQuery.of(context);
        return ColoredBox(
          color: const Color(0xFF292832),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox.fromSize(
                  size: tamanho,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: MediaQuery(
                      data: midia.copyWith(
                        size: tamanho,
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// TELA 1 — CÓDICE
// ============================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Login → app. pushReplacement: o login sai da pilha, então o
  /// voltar do Android dentro do app não cai de novo nesta tela.
  void goToApp(BuildContext context) {
    debugPrint('[login] entrando: pushReplacementNamed(${Rotas.app})');
    Navigator.of(context).pushReplacementNamed(Rotas.app);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Início',
                    style: TextStyle(
                      color: Color(0xFFAAA7B3),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const StatusBar(),
                ],
              ),
              const SizedBox(height: 27),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 19,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1725),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Positioned(
                      right: 13,
                      top: 10,
                      child: Container(
                        width: 3,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Códice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Nuvem Assistencial de Visualização Interativa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF77727F),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 29),
              Container(
                width: 143,
                height: 143,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00C5C2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Image(
                    image: frostImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D4C1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'IRIS - guia',
                    style: TextStyle(
                      color: Color(0xFF00D4C1),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Se precisar de alguma ajuda, só\n'
                'clicar em meu ícone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC5C1CB),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => goToApp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    foregroundColor: const Color(0xFF0D0B13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'criar meu NAVI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: () => goToApp(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF474252)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'já tenho um códice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 186,
                height: 1,
                color: const Color(0xFF25222D),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APP SHELL — DRAWER + BOTTOMNAVIGATIONBAR + UM NAVIGATOR POR ABA
// ============================================================

/// As abas do BottomNavigationBar. Cada uma tem um Navigator próprio que
/// começa na rota indicada aqui.
class Aba {
  final String nome;
  final String rota;
  final IconData icone;

  const Aba(this.nome, this.rota, this.icone);
}

const List<Aba> abas = [
  Aba('Navi', Rotas.navi, Icons.sentiment_satisfied_alt_outlined),
  Aba('Conversa', Rotas.conversa, Icons.chat_bubble_outline),
  Aba('Diário', Rotas.diario, Icons.article_outlined),
  Aba('Cidade', Rotas.cidade, Icons.account_balance_outlined),
  Aba('Encontros', Rotas.encontros, Icons.people_outline),
];

class AppShell extends StatefulWidget {
  final int abaInicial;

  const AppShell({super.key, this.abaInicial = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int selectedIndex = widget.abaInicial;

  final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();

  /// Um Navigator por aba. O IndexedStack mantém todos vivos, então a
  /// pilha de cada um continua lá quando a pessoa troca de aba.
  final List<GlobalKey<NavigatorState>> _navegadores = [
    for (final _ in abas) GlobalKey<NavigatorState>(),
  ];

  final List<ObservadorDaPilha> _observadores = [
    for (final aba in abas) ObservadorDaPilha(aba.nome),
  ];

  NavigatorState? get _navegadorAtual =>
      _navegadores[selectedIndex].currentState;

  void _trocarAba(int index) {
    // Trocar de aba some com o aviso da aba anterior.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (index == selectedIndex) {
      // Tocar de novo na aba aberta volta para a raiz dela.
      debugPrint('[abas] ${abas[index].nome} de novo: popUntil(raiz)');
      _navegadorAtual?.popUntil((rota) => rota.isFirst);
      return;
    }
    debugPrint('[abas] ${abas[selectedIndex].nome} -> ${abas[index].nome}'
        '  (pilha preservada: [${_observadores[index].pilha}])');
    setState(() => selectedIndex = index);
  }

  /// Botão voltar do sistema. Ele chega no Navigator RAIZ, que não sabe
  /// nada das pilhas das abas; o PopScope intercepta e a decisão é aqui:
  /// 1. Drawer aberto: fecha o Drawer.
  /// 2. A aba tem histórico: pop dentro da própria aba.
  /// 3. A aba está na raiz: volta para a aba Navi.
  /// 4. Já está na raiz da Navi: fecha o app.
  void _voltar() {
    final scaffold = _scaffold.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      debugPrint('[voltar] fecha o Drawer');
      scaffold.closeDrawer();
      return;
    }
    final navegador = _navegadorAtual;
    if (navegador != null && navegador.canPop()) {
      debugPrint('[voltar] pop na pilha da aba ${abas[selectedIndex].nome}');
      navegador.maybePop();
      return;
    }
    if (selectedIndex != 0) {
      debugPrint('[voltar] ${abas[selectedIndex].nome} já está na raiz: '
          'vai para a aba Navi');
      _trocarAba(0);
      return;
    }
    debugPrint('[voltar] raiz da aba Navi: fecha o app');
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        key: _scaffold,
        backgroundColor: kBg,
        drawer: const MenuLateral(),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: selectedIndex,
            children: [
              for (var i = 0; i < abas.length; i++)
                Navigator(
                  key: _navegadores[i],
                  observers: [_observadores[i]],
                  onGenerateInitialRoutes: (_, _) => [
                    Rotas.gerar(RouteSettings(name: abas[i].rota))!,
                  ],
                  onGenerateRoute: Rotas.gerar,
                ),
            ],
          ),
        ),
        // No slot próprio do Scaffold, as SnackBars flutuam ACIMA da barra
        // em vez de cobrirem a navegação.
        bottomNavigationBar: SafeArea(
          top: false,
          child: BottomNavigation(
            selectedIndex: selectedIndex,
            onSelected: _trocarAba,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DRAWER — AÇÕES COMPLEMENTARES
// ============================================================

/// Abre o Drawer do AppShell. As telas-raiz das abas não têm Scaffold
/// próprio, então o Scaffold.of encontra o do AppShell.
class BotaoMenu extends StatelessWidget {
  const BotaoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: 'abrir menu',
        child: InkResponse(
          radius: 18,
          onTap: () {
            debugPrint('[drawer] abrir');
            Scaffold.of(context).openDrawer();
          },
          child: const Icon(Icons.menu, size: 18, color: Color(0xFFC5C1CB)),
        ),
      ),
    );
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  /// push: Configurações entra POR CIMA do app na pilha raiz. O voltar
  /// tira ela e o app reaparece do jeito que estava.
  void _configuracoes(BuildContext context) {
    Scaffold.of(context).closeDrawer();
    debugPrint('[drawer] Configurações: pushNamed(${Rotas.configuracoes})');
    Navigator.of(context).pushNamed(Rotas.configuracoes);
  }

  /// Modal simples: não é uma tela, é um diálogo por cima.
  void _sobre(BuildContext context) {
    Scaffold.of(context).closeDrawer();
    debugPrint('[drawer] Sobre: showDialog');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kLine),
        ),
        icon: const Icon(Icons.auto_stories_outlined, color: kPurple),
        title: const Text(
          'Códice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Um diário pessoal onde uma criatura digital aprende com a '
          'convivência.\n\n'
          'Disciplina de Desenvolvimento para Dispositivos Móveis.\n'
          'Ramon Couto Santo e Aaron Guerra Goldberg.',
          style: TextStyle(
            color: Color(0xFFE4E0E9),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('fechar'),
          ),
        ],
      ),
    );
  }

  /// pushReplacement: o app SAI da pilha e o login entra no lugar dele.
  /// Depois do logout, o voltar não consegue retornar para dentro do app.
  void _sair(BuildContext context) {
    debugPrint('[drawer] Sair: pushReplacementNamed(${Rotas.login})');
    Navigator.of(context).pushReplacementNamed(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kPanel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C5C2)),
                    ),
                    child: ClipOval(
                      child: Image(
                        image: frostRostoImage,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'NAVI · 8 anos · criança',
                        style: TextStyle(color: kPurple2, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: kLine, height: 1),
            const SizedBox(height: 8),
            _item(
              icone: Icons.settings_outlined,
              titulo: 'Configurações',
              subtitulo: 'sons, avisos e cidade',
              onTap: () => _configuracoes(context),
            ),
            _item(
              icone: Icons.info_outline,
              titulo: 'Sobre',
              subtitulo: 'o que é o Códice',
              onTap: () => _sobre(context),
            ),
            const Spacer(),
            const Divider(color: kLine, height: 1),
            _item(
              icone: Icons.logout,
              titulo: 'Sair',
              subtitulo: 'voltar para a tela de entrada',
              cor: const Color(0xFFFF8A8A),
              onTap: () => _sair(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color cor = const Color(0xFFE4E0E9),
  }) {
    return ListTile(
      leading: Icon(icone, color: cor, size: 20),
      title: Text(titulo, style: TextStyle(color: cor, fontSize: 13)),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(color: Color(0xFF8B8498), fontSize: 10),
      ),
      onTap: onTap,
    );
  }
}

// ============================================================
// CABEÇALHOS REUTILIZADOS PELAS TELAS NOVAS
// ============================================================

/// Cabeçalho das telas-raiz de aba: menu, título e relógio.
class CabecalhoAba extends StatelessWidget {
  final String titulo;

  const CabecalhoAba(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 0),
      child: Row(
        children: [
          const BotaoMenu(),
          Text(
            titulo,
            style: const TextStyle(color: Color(0xFF8D8996), fontSize: 14),
          ),
          const Spacer(),
          const StatusBar(),
        ],
      ),
    );
  }
}

/// Cabeçalho das telas empilhadas: a seta faz pop no Navigator mais
/// próximo (o da aba, ou o raiz no caso das Configurações).
class CabecalhoDetalhe extends StatelessWidget {
  final String titulo;

  const CabecalhoDetalhe(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'voltar',
            child: InkResponse(
              radius: 18,
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, size: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8D8996), fontSize: 14),
            ),
          ),
          const StatusBar(),
        ],
      ),
    );
  }
}

/// Título grande logo abaixo do cabeçalho.
class TituloGrande extends StatelessWidget {
  final String texto;
  final String? subtitulo;

  const TituloGrande(this.texto, {super.key, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitulo!,
              style: const TextStyle(color: Color(0xFF8B8595), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CONFIGURAÇÕES (push na pilha raiz)
// ============================================================

/// Dados mockados, só em memória.
class Ajustes {
  Ajustes._();

  static bool falasEmNavides = true;
  static bool avisarEncontros = true;
  static bool relatoDaCidade = false;
}

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

// ============================================================
// STATUS BAR
// ============================================================

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '21:04',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 6),
        Icon(Icons.signal_cellular_alt, size: 13, color: Colors.white),
        SizedBox(width: 4),
        Icon(Icons.wifi, size: 13, color: Colors.white),
        SizedBox(width: 4),
        Icon(Icons.battery_full, size: 16, color: Colors.white),
      ],
    );
  }
}

// ============================================================
// TELA 2 — HOME / NAVI
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Uma margem só para a tela inteira: é o que faz as bordas do palco,
  /// do cartão e dos botões caírem na mesma linha.
  static const double margem = 16;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(margem, 5, margem, margem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              BotaoMenu(),
              Text(
                'Home',
                style: TextStyle(color: Color(0xFF8D8996), fontSize: 14),
              ),
              Spacer(),
              StatusBar(),
            ],
          ),
          const SizedBox(height: 20),
          _cabecalho(),
          const SizedBox(height: 14),
          _palco(),
          const SizedBox(height: 14),
          _pergunta(),
          const SizedBox(height: 12),
          Row(
            children: [
              _acao(Icons.article_outlined, 'escrever'),
              const SizedBox(width: 8),
              _acao(Icons.search, 'lembrar'),
              const SizedBox(width: 8),
              _acao(Icons.alarm, 'alarme'),
              const SizedBox(width: 8),
              _acao(Icons.mic_none, 'falar'),
            ],
          ),
          const SizedBox(height: 16),
          _vigor(78),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        const Text(
          'Frost',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF171522),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF383345)),
          ),
          child: const Text(
            '8 anos • criança',
            style: TextStyle(
              color: Color(0xFFB8B2C5),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF211A3B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF45356F)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_natural, color: kPurple, size: 13),
              SizedBox(width: 5),
              Text(
                'ficha',
                style: TextStyle(
                  color: kPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// O palco da Frost. A ordem do Stack é a profundidade: metade de trás
  /// dos anéis → Frost → metade da frente. Assim ela fica DENTRO dos
  /// anéis, com os pés no centro, em vez de ter linhas riscando as botas.
  Widget _palco() {
    const alturaChao = 44.0;
    const baseDoChao = 12.0;
    // Os pés ficam exatamente no centro das elipses.
    const pes = baseDoChao + alturaChao / 2;

    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF5A4B87)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [
                      const Color(0xFF192235).withValues(alpha: 0.8),
                      const Color(0xFF111624).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: baseDoChao,
              height: alturaChao,
              child: CustomPaint(
                painter: GroundCirclesPainter(metade: MetadeDoChao.tras),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 16,
              bottom: pes,
              child: Image(
                image: frostImage,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: baseDoChao,
              height: alturaChao,
              child: CustomPaint(
                painter: GroundCirclesPainter(metade: MetadeDoChao.frente),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pergunta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF36250D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5B411B)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: Color(0xFFF0B74B),
                      size: 15,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'ela quer entender uma coisa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFF0B74B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7),
                Text(
                  '«Você mudou de emprego?»',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'dois fatos que ela guarda se contradizem.',
                  style: TextStyle(color: Color(0xFF918676), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0B74B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'resolver',
              style: TextStyle(
                color: Color(0xFF251A09),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acao(IconData icone, String rotulo) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: kPurple, size: 18),
            const SizedBox(height: 7),
            Text(
              rotulo,
              style: const TextStyle(
                color: Color(0xFFB2ADBE),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de vigor com o valor de verdade: antes ela ficava sempre
  /// cheia, mesmo mostrando 78.
  Widget _vigor(int valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'VIGOR',
              style: TextStyle(
                color: Color(0xFF8D879B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '$valor',
              style: const TextStyle(
                color: Color(0xFFB9B3C3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: valor / 100,
            minHeight: 7,
            backgroundColor: const Color(0xFF232030),
            color: const Color(0xFF65D6D6),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'descansou bem, sem desgaste acumulado.',
          style: TextStyle(color: Color(0xFF777181), fontSize: 9),
        ),
      ],
    );
  }
}

// ============================================================
// TELA 3 — CONVERSA COM O NAVI
// ============================================================

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool listening = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BotaoMenu(),
                      const Text(
                        'Conversa com o NAVI',
                        style: TextStyle(
                          color: Color(0xFF8D8996),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const StatusBar(),
                    ],
                  ),
                  const SizedBox(height: 21),
                  Row(
                    children: [
                      const Text(
                        'Conversa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07382B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF52D9A2),
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'off-line',
                              style: TextStyle(
                                color: Color(0xFF52D9A2),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time_outlined,
                        color: Color(0xFFBDB8C9),
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'hoje',
                    style: TextStyle(
                      color: Color(0xFF8C8798),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _incomingMessage(
                    'oi. você dormiu mal a semana\ntoda — quer que eu te lembre?',
                  ),
                  const SizedBox(height: 13),
                  _outgoingMessage('me acorda sete e meia'),
                  const SizedBox(height: 13),
                  _incomingMessage('marquei. bom descanso.'),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 44),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF211F2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF302D3B)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4A27),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.alarm,
                            color: Color(0xFFF2C24C),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '07:30',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'amanhã · Relógio do sistema',
                                style: TextStyle(
                                  color: Color(0xFF87818F),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'abrir',
                          style: TextStyle(
                            color: kPurple,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  Container(
                    margin: const EdgeInsets.only(left: 44),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171620),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF302D3B)),
                    ),
                    child: const Text(
                      'a prova é quinta, né?',
                      style: TextStyle(
                        color: Color(0xFFE1DEE7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  Container(
                    width: double.infinity,
                    height: 79,
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF211B3A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4A3A76)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'ouvindo...',
                              style: TextStyle(
                                color: kPurple2,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.verified_user_outlined,
                              color: kPurple,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'no aparelho',
                              style: TextStyle(
                                color: Color(0xFF9C91C2),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _waveform(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 51,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171620),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFF302D3B)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'escrever para a Frost...',
                          style: TextStyle(
                            color: Color(0xFF898394),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add,
                        color: Color(0xFF9B96A4),
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  setState(() => listening = !listening);
                },
                child: Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: listening ? kPurple : const Color(0xFF211B3A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: listening
                          ? kPurple
                          : const Color(0xFF4A3A76),
                    ),
                  ),
                  child: Icon(
                    listening ? Icons.mic : Icons.mic_none,
                    color: const Color(0xFF171322),
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _incomingMessage(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 44,
          margin: const EdgeInsets.only(top: 1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: frostRostoImage,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1924),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border.all(color: const Color(0xFF302D3B)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE5E1EA),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outgoingMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 198),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF241D40),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
          border: Border.all(color: const Color(0xFF49396F)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _waveform() {
    const heights = [
      5.0, 12.0, 18.0, 10.0, 25.0, 12.0, 17.0, 9.0,
      22.0, 27.0, 14.0, 22.0, 9.0, 16.0, 23.0, 13.0,
      18.0, 11.0, 24.0, 16.0, 11.0, 7.0, 18.0, 12.0,
      7.0,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: heights.map((h) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: const Color(0xFF7966C5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// TELA 4 — DIÁRIO (tela interativa da atividade de eventos)
//
// Todo evento desta tela percorre o mesmo ciclo:
//   captura → processamento → resposta
// (e-book, cap. 6, "O princípio da orquestração de eventos").
//
// Mapa dos eventos:
//   TextField ........ onChanged  → conta palavras, acende etiquetas,
//                                   libera ou bloqueia o botão guardar
//   guardar .......... onPressed  → valida → AlertDialog → "lendo..." →
//                                   memória → SnackBar → (contradição?)
//   apagar ........... onPressed  → só explica (evita perda sem querer)
//                      onLongPress→ apaga, com "desfazer" na SnackBar
//   Frost ............ onTap / onDoubleTap / onLongPress
//   etiquetas ........ onTap (InkWell) marca/desmarca; "+" abre diálogo
// ============================================================

/// Uma entrada que a Frost aceitou guardar. Vive só na sessão: a
/// atividade é sobre eventos, não sobre persistência.
class Memoria {
  final String texto;
  final Set<String> etiquetas;
  final DateTime quando;

  Memoria(this.texto, this.etiquetas, this.quando);
}

/// Como a Frost está reagindo agora. Cada evento empurra um humor, e o
/// humor decide a cor da borda e o ícone do balão — o feedback visual.
enum Humor { esperando, lendo, curiosa, feliz, confusa, pensando }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  /// Abaixo disso ela "ainda não entende" e o botão guardar fica travado.
  static const int minimoPalavras = 5;

  /// Palavras que acendem cada etiqueta. É a leitura dela: simples,
  /// previsível e sem IA — só o que você escreveu.
  /// Cada pista é o COMEÇO de uma palavra: "bia" acende com "Bia", mas
  /// não com "sabia"; "trabalh" pega "trabalho" e "trabalhei".
  static const Map<String, List<String>> pistas = {
    'prova': ['prova', 'exame', 'estud'],
    'sono': ['dormi', 'sono', 'olho', 'acordei', 'cansad'],
    'Bia': ['bia'],
    'emprego': ['emprego', 'trabalh'],
    'comida': ['almoç', 'almoc', 'jant', 'comid', 'comer'],
  };

  final TextEditingController _texto = TextEditingController();
  final FocusNode _foco = FocusNode();

  /// Começa com uma memória antiga de propósito: é ela que permite
  /// demonstrar a contradição ("você mudou de emprego?").
  final List<Memoria> _memorias = [
    Memoria('Trabalho na livraria do centro.', {'emprego'},
        DateTime(2026, 9, 1)),
  ];

  final Set<String> _removidas = {}; // sugeridas que a pessoa recusou
  final Set<String> _extras = {}; // criadas à mão pelo "+"

  int _palavras = 0;
  bool _processando = false;
  Humor _humor = Humor.esperando;
  String _fala = 'oi. me conta como foi o dia — eu só sei o que você me ensina.';
  double _conhecimento = 0.22; // barra "rumo aos 14 anos"
  int _carinhos = 0;
  bool _pulando = false;
  Timer? _voltarAoNormal;
  Timer? _fimDoPulo;

  /// A pergunta da contradição ficou para depois porque a pessoa saiu
  /// do Diário antes dela aparecer (o IndexedStack mantém esta tela viva).
  bool _contradicaoPendente = false;

  @override
  void initState() {
    super.initState();
    // Foco também é evento: a borda da página acende quando o campo
    // ganha foco e apaga quando perde.
    _foco.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Visibility.of registra dependência: este método roda de novo quando
  /// a aba do Diário aparece ou some. Se havia pergunta guardada, ela sai
  /// agora — nunca por cima de outra aba.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contradicaoPendente && Visibility.of(context)) {
      _contradicaoPendente = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _perguntarContradicao();
      });
    }
  }

  @override
  void dispose() {
    _voltarAoNormal?.cancel();
    _fimDoPulo?.cancel();
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------- estado lido

  bool get _podeGuardar => _palavras >= minimoPalavras && !_processando;

  Set<String> get _detectadas {
    // Separa por qualquer coisa que não seja letra (inclui acentuadas).
    final palavras = _texto.text
        .toLowerCase()
        .split(RegExp(r'[^a-zà-ÿ]+'))
        .where((p) => p.isNotEmpty);
    return {
      for (final pista in pistas.entries)
        if (palavras.any((w) => pista.value.any(w.startsWith))) pista.key,
    };
  }

  Set<String> get _etiquetas =>
      {..._detectadas.difference(_removidas), ..._extras};

  int _contarPalavras(String valor) {
    final limpo = valor.trim();
    return limpo.isEmpty ? 0 : limpo.split(RegExp(r'\s+')).length;
  }

  // ------------------------------------------------------------- respostas

  /// A Frost fala. Um evento novo cancela o timer do anterior: quem
  /// chega por último vence, então dois toques rápidos nunca embaralham
  /// as falas (eventos concorrentes tratados de forma previsível).
  void _falar(String texto, Humor humor) {
    _voltarAoNormal?.cancel();
    setState(() {
      _fala = texto;
      _humor = humor;
      _pulando = true;
    });
    _fimDoPulo?.cancel();
    _fimDoPulo = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pulando = false);
    });
    _voltarAoNormal = Timer(const Duration(seconds: 5), () {
      if (!mounted || _processando) return;
      setState(() {
        _humor = _palavras == 0 ? Humor.esperando : Humor.lendo;
      });
    });
  }

  /// SnackBar única: esconde a anterior antes de mostrar a nova, para os
  /// avisos não formarem fila e o último evento ser sempre o que aparece.
  void _avisar(
    String mensagem, {
    IconData icone = Icons.info_outline,
    SnackBarAction? acao,
  }) {
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF211B3A),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF4A3A76)),
        ),
        content: Row(
          children: [
            Icon(icone, color: kPurple, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        action: acao,
      ),
    );
  }

  // ---------------------------------------------- 1. entrada em tempo real

  void _aoDigitar(String valor) {
    final antes = _palavras;
    final agora = _contarPalavras(valor);
    debugPrint('[Diário] onChanged → "$valor" ($agora palavras)');

    setState(() {
      _palavras = agora;
      if (!_processando) {
        _humor = agora == 0 ? Humor.esperando : Humor.lendo;
      }
    });

    // Encadeamento: cruzar o limite em qualquer direção faz ela reagir.
    if (antes < minimoPalavras && agora >= minimoPalavras) {
      _falar('agora eu entendi o suficiente pra guardar.', Humor.curiosa);
    } else if (antes >= minimoPalavras && agora < minimoPalavras && agora > 0) {
      _falar('hm, ficou curto de novo.', Humor.pensando);
    }
  }

  // ------------------------------------------ 2. ação principal (guardar)

  Future<void> _guardar() async {
    if (!_podeGuardar) return; // defesa extra: o botão já vem travado
    debugPrint('[Diário] onPressed guardar → validando');
    _foco.unfocus();

    // Trava enquanto o fluxo não termina: toque duplo no botão não cria
    // duas memórias, e os outros controles esperam a vez.
    setState(() => _processando = true);

    final texto = _texto.text.trim();
    final etiquetas = _etiquetas;

    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kLine),
        ),
        title: const Text(
          'Posso guardar isso?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '«$texto»',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE4E0E9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              etiquetas.isEmpty
                  ? 'sem etiqueta — vai como "geral".'
                  : 'etiquetas: ${etiquetas.join(', ')}',
              style: const TextStyle(color: kPurple2, fontSize: 11),
            ),
            const SizedBox(height: 6),
            const Text(
              'nada vira memória sem você confirmar.',
              style: TextStyle(color: Color(0xFF8B8498), fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ainda não'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPurple,
              foregroundColor: const Color(0xFF171322),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('pode guardar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmou != true) {
      setState(() => _processando = false);
      _falar('tá bom. continuo só lendo.', Humor.pensando);
      return;
    }

    // Processamento simulado: dá tempo de ver que ela está "lendo".
    setState(() {
      _humor = Humor.lendo;
      _fala = 'lendo...';
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final contradiz = etiquetas.contains('emprego') &&
        _memorias.any((m) => m.etiquetas.contains('emprego'));
    final nova = Memoria(
      texto,
      etiquetas.isEmpty ? {'geral'} : etiquetas,
      DateTime.now(),
    );

    setState(() {
      _memorias.insert(0, nova);
      final subiu = _conhecimento + 0.08;
      _conhecimento = subiu > 1 ? 1.0 : subiu;
      _texto.clear();
      _palavras = 0;
      _removidas.clear();
      _extras.clear();
      _processando = false;
    });

    _falar(
      'guardei. agora eu sei ${_memorias.length} coisas sobre você.',
      Humor.feliz,
    );
    _avisar(
      'memória guardada · ${nova.etiquetas.join(', ')}',
      icone: Icons.bookmark_added_outlined,
      acao: SnackBarAction(
        label: 'ver',
        textColor: kPurple,
        onPressed: _abrirMemorias, // encadeamento: aviso → lista
      ),
    );

    // Encadeamento automático: se o fato novo bate de frente com um
    // antigo, ela pergunta sozinha, sem ninguém apertar nada.
    if (contradiz) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      // Se a pessoa trocou de aba nesse meio-tempo, a pergunta espera ela
      // voltar (ver didChangeDependencies).
      if (Visibility.of(context)) {
        await _perguntarContradicao();
      } else {
        _contradicaoPendente = true;
      }
    }
  }

  Future<void> _perguntarContradicao() async {
    // A memória nova está no índice 0; a antiga é a próxima de emprego.
    final antigas =
        _memorias.skip(1).where((m) => m.etiquetas.contains('emprego'));
    if (antigas.isEmpty) return;
    final antiga = antigas.first;
    _falar('espera... isso não bate com o que eu sabia.', Humor.confusa);

    final mudou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF36250D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF5B411B)),
        ),
        icon: const Icon(Icons.favorite_border, color: Color(0xFFF0B74B)),
        title: const Text(
          '«Você mudou de emprego?»',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'antes você me contou: «${antiga.texto}»\n\n'
          'dois fatos que eu guardo se contradizem.',
          style: const TextStyle(color: Color(0xFFD9CBB4), fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'não, é o mesmo',
              style: TextStyle(color: Color(0xFFF0B74B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF0B74B),
              foregroundColor: const Color(0xFF251A09),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('sim, mudei'),
          ),
        ],
      ),
    );

    if (!mounted || mudou == null) return;
    if (mudou) setState(() => _memorias.remove(antiga));
    _falar(
      mudou
          ? 'anotado. troquei o que eu sabia.'
          : 'ok. os dois continuam valendo.',
      mudou ? Humor.feliz : Humor.pensando,
    );
    _avisar(
      mudou ? 'memória antiga substituída' : 'as duas memórias foram mantidas',
      icone: Icons.sync_alt,
    );
  }

  // --------------------------------------------- 3. ação secundária (apagar)

  /// Toque curto só explica. Apagar é destrutivo, então exige um gesto
  /// que não acontece por acidente (e-book: "um botão chamado Excluir
  /// deve solicitar confirmação antes de agir").
  void _dicaApagar() {
    debugPrint('[Diário] onPressed apagar → só dica');
    _avisar(
      _texto.text.isEmpty
          ? 'não tem nada para apagar.'
          : 'segure o botão para apagar — assim nada some sem querer.',
      icone: Icons.touch_app_outlined,
    );
  }

  void _apagar() {
    debugPrint('[Diário] onLongPress apagar');
    final backup = _texto.text;
    if (backup.isEmpty) {
      _avisar('não tem nada para apagar.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _texto.clear();
      _palavras = 0;
      _removidas.clear();
      _extras.clear();
    });
    _falar('apagou? tudo bem, eu ainda não tinha guardado.', Humor.pensando);
    _avisar(
      'texto apagado',
      icone: Icons.delete_outline,
      acao: SnackBarAction(
        label: 'desfazer',
        textColor: kPurple,
        onPressed: () {
          // Se já escreveu outra coisa, desfazer não pode atropelar.
          if (_texto.text.isNotEmpty) {
            _avisar('você já escreveu outra coisa — o texto antigo não '
                'voltou para não apagar o novo.');
            return;
          }
          _texto.value = TextEditingValue(
            text: backup,
            selection: TextSelection.collapsed(offset: backup.length),
          );
          // Mudança feita por código não dispara onChanged — o evento
          // é encadeado à mão para o contador e as etiquetas voltarem.
          _aoDigitar(backup);
        },
      ),
    );
  }

  // --------------------------------------------------- 4. gestos na Frost

  void _tocarFrost() {
    debugPrint('[Diário] onTap na Frost');
    if (_processando) return;
    final n = _palavras;
    final falta = minimoPalavras - n;
    final String fala;
    if (n == 0) {
      fala = 'tô esperando você escrever. pode ser pouco.';
    } else if (falta > 0) {
      fala = 'li $n ${n == 1 ? 'palavra' : 'palavras'}. '
          'me conta mais $falta?';
    } else {
      final e = _etiquetas;
      fala = 'entendi: ${e.isEmpty ? 'um dia comum' : e.join(', ')}. '
          'posso guardar?';
    }
    _falar(fala, Humor.curiosa);
  }

  void _carinhoFrost() {
    debugPrint('[Diário] onDoubleTap na Frost');
    if (_processando) return;
    setState(() => _carinhos++);
    _falar(
      _carinhos == 1 ? 'hehe. isso foi um carinho?' : 'de novo! ($_carinhos)',
      Humor.feliz,
    );
  }

  void _segurarFrost() {
    debugPrint('[Diário] onLongPress na Frost');
    if (_processando) return;
    HapticFeedback.selectionClick();
    _abrirMemorias();
  }

  void _abrirMemorias() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kPanel,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'o que a Frost sabe (${_memorias.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'só o que você confirmou.',
              style: TextStyle(color: Color(0xFF8B8498), fontSize: 10),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _memorias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CartaoMemoria(_memorias[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ etiquetas

  void _alternarEtiqueta(String nome) {
    debugPrint('[Diário] onTap etiqueta "$nome"');
    setState(() {
      if (_extras.contains(nome)) {
        _extras.remove(nome);
      } else if (_removidas.contains(nome)) {
        _removidas.remove(nome);
      } else {
        _removidas.add(nome);
      }
    });
    final ativa = _etiquetas.contains(nome);
    _falar(
      ativa ? 'ok, é sobre $nome.' : 'entendi, não é sobre $nome.',
      Humor.pensando,
    );
  }

  Future<void> _novaEtiqueta() async {
    // O controller não é descartado aqui de propósito: o diálogo ainda
    // usa o campo durante a animação de saída.
    final campo = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text(
          'nova etiqueta',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: campo,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'ex: família'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, campo.text.trim()),
            child: const Text('adicionar'),
          ),
        ],
      ),
    );
    if (!mounted || nome == null || nome.isEmpty) return;
    setState(() => _extras.add(nome));
    _falar('$nome. vou lembrar dessa palavra.', Humor.curiosa);
  }

  // ----------------------------------------------------------------- tela

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    BotaoMenu(),
                    Text(
                      'Diário',
                      style: TextStyle(color: Color(0xFF8D8996), fontSize: 14),
                    ),
                    Spacer(),
                    StatusBar(),
                  ],
                ),
                const SizedBox(height: 20),
                _cabecalho(),
                const SizedBox(height: 14),
                _frostQueLe(),
                const SizedBox(height: 14),
                _pagina(),
                const SizedBox(height: 16),
                _secaoEtiquetas(),
                const SizedBox(height: 16),
                _aviso(),
              ],
            ),
          ),
        ),
        _rodape(),
      ],
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diário',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dataDeHoje(),
                style: const TextStyle(color: Color(0xFF77727F), fontSize: 10),
              ),
            ],
          ),
        ),
        // Atalho para a mesma lista do long press na Frost.
        InkWell(
          onTap: _abrirMemorias,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF211A3B),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF45356F)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmarks_outlined, color: kPurple, size: 13),
                const SizedBox(width: 5),
                Text(
                  '${_memorias.length} memórias',
                  style: const TextStyle(
                    color: kPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Seção da Frost: a área de gestos e o balão onde ela responde.
  Widget _frostQueLe() {
    final cor = _corDoHumor(_humor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _tocarFrost,
              onDoubleTap: _carinhoFrost,
              onLongPress: _segurarFrost,
              child: AnimatedScale(
                scale: _pulando ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111624),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: cor, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(
                      image: frostRostoImage,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1924),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border.all(color: cor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_iconeDoHumor(_humor), color: cor, size: 12),
                        const SizedBox(width: 5),
                        const Text(
                          'Frost · 8 anos',
                          style: TextStyle(
                            color: Color(0xFFB8B2C5),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_carinhos > 0) ...[
                          const Icon(Icons.favorite,
                              color: Color(0xFFFF8FB1), size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '$_carinhos',
                            style: const TextStyle(
                              color: Color(0xFFFF8FB1),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _fala,
                      style: const TextStyle(
                        color: Color(0xFFE5E1EA),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Flexible + ellipsis: com fonte do sistema maior ou tela
            // estreita, a dica encolhe em vez de estourar a linha.
            const Flexible(
              child: Text(
                'toque · dois toques · segure',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF6F6A7C), fontSize: 8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _conhecimento,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF2A2640),
                  color: const Color(0xFF65D6D6),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'rumo aos 14',
              style: TextStyle(color: Color(0xFF8D879B), fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  /// A página do diário: o campo de texto e o contador ao vivo.
  Widget _pagina() {
    final falta = minimoPalavras - _palavras;
    final pronto = falta <= 0;
    final corStatus = pronto ? const Color(0xFF52D9A2) : const Color(0xFFF0B74B);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1924),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _foco.hasFocus ? const Color(0xFF4A3A76) : const Color(0xFF302D3B),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _texto,
              focusNode: _foco,
              enabled: !_processando,
              onChanged: _aoDigitar,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              cursorColor: kPurple,
              style: const TextStyle(
                color: Color(0xFFE4E0E9),
                fontSize: 13,
                height: 1.55,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(top: 6),
                hintText: 'Acordei mal de novo, não preguei o olho. '
                    'A prova de física ficou pra quinta...',
                hintStyle: TextStyle(
                  color: Color(0xFF5E5869),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFF2D2937)),
          Row(
            children: [
              Text(
                '$_palavras ${_palavras == 1 ? 'palavra' : 'palavras'}',
                style: const TextStyle(
                  color: Color(0xFF888294),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                pronto ? Icons.check_circle_outline : Icons.hourglass_empty,
                color: corStatus,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  pronto
                      ? 'ela já consegue guardar'
                      : 'faltam $falta para ela entender',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secaoEtiquetas() {
    final detectadas = _detectadas;
    final nomes = [...detectadas, ..._extras.where((e) => !detectadas.contains(e))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ETIQUETAS SUGERIDAS',
          style: TextStyle(
            color: Color(0xFF8D879B),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (nomes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(
                  'aparecem enquanto você escreve',
                  style: TextStyle(color: Color(0xFF6F6A7C), fontSize: 10),
                ),
              ),
            for (final nome in nomes)
              _Etiqueta(
                nome: nome,
                ativa: _etiquetas.contains(nome),
                onTap: _processando ? null : () => _alternarEtiqueta(nome),
              ),
            InkWell(
              onTap: _processando ? null : _novaEtiqueta,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B3A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF493A70)),
                ),
                child: const Icon(Icons.add, color: kPurple, size: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aviso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF211F2B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF302D3B)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_outlined, color: Color(0xFF8F899B), size: 17),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'escreva solto, do tamanho que der\n',
                    style: TextStyle(
                      color: Color(0xFFE2DEE8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'de madrugada, carregando, ela lê o dia e propõe '
                        'fatos. nada vira memória sem você confirmar.',
                    style: TextStyle(
                      color: Color(0xFF777181),
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rodapé fixo, fora da rolagem: as duas ações ficam sempre à mão.
  Widget _rodape() {
    final falta = minimoPalavras - _palavras;

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 6, 17, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                // null = desabilitado: a condição fica visível no próprio
                // botão em vez de virar um erro depois do clique.
                onPressed: _podeGuardar ? _guardar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: const Color(0xFF171322),
                  disabledBackgroundColor: const Color(0xFF2A2640),
                  disabledForegroundColor: const Color(0xFF7D778A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _processando
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFB9B3C3),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'guardando...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        falta > 0
                            ? 'escreva mais $falta ${falta == 1 ? 'palavra' : 'palavras'}'
                            : 'guardar no diário',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: _processando ? null : _dicaApagar,
              onLongPress: _processando ? null : _apagar,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF211B3A),
                foregroundColor: kPurple,
                side: const BorderSide(color: Color(0xFF493A70)),
              ),
              child: const Icon(Icons.delete_outline, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ auxiliares

  static Color _corDoHumor(Humor h) => switch (h) {
        Humor.esperando => const Color(0xFF302D3B),
        Humor.lendo => kPurple,
        Humor.curiosa => const Color(0xFF65D6D6),
        Humor.feliz => const Color(0xFFFF8FB1),
        Humor.confusa => const Color(0xFFF0B74B),
        Humor.pensando => const Color(0xFF8D879B),
      };

  static IconData _iconeDoHumor(Humor h) => switch (h) {
        Humor.esperando => Icons.more_horiz,
        Humor.lendo => Icons.menu_book_outlined,
        Humor.curiosa => Icons.lightbulb_outline,
        Humor.feliz => Icons.favorite,
        Humor.confusa => Icons.help_outline,
        Humor.pensando => Icons.psychology_outlined,
      };

  static String _dataDeHoje() {
    const dias = [
      'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo',
    ];
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
      'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final d = DateTime.now();
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }
}

/// Etiqueta tocável. InkWell em vez de GestureDetector porque aqui o
/// retorno visual do toque (a onda) já é parte do feedback.
class _Etiqueta extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback? onTap;

  const _Etiqueta({required this.nome, required this.ativa, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Ink(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ativa ? const Color(0xFF241D40) : const Color(0xFF211F2B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: ativa ? const Color(0xFF6A56B8) : const Color(0xFF373342),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ativa ? Icons.check : Icons.close,
              size: 11,
              color: ativa ? kPurple : const Color(0xFF6F6A7C),
            ),
            const SizedBox(width: 4),
            Text(
              nome,
              style: TextStyle(
                color: ativa ? const Color(0xFFD9D2F5) : const Color(0xFF6F6A7C),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                decoration: ativa ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoMemoria extends StatelessWidget {
  final Memoria memoria;

  const _CartaoMemoria(this.memoria);

  @override
  Widget build(BuildContext context) {
    final q = memoria.quando;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1924),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF302D3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoria.texto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE4E0E9), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '${memoria.etiquetas.join(' · ')}  ·  ${q.day}/${q.month}',
            style: const TextStyle(color: kPurple2, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CIDADE (aba com pilha: lista -> lugar)
// ============================================================

class Lugar {
  final String nome;
  final String descricao;
  final String comoRevelou;
  final IconData icone;

  const Lugar(this.nome, this.descricao, this.comoRevelou, this.icone);
}

/// Dados mockados da NAVICity.
const List<Lugar> lugares = [
  Lugar(
    'Praça dos Bipes',
    'Onde os NAVIs treinam Navidês no fim da tarde. A Frost costuma '
        'ficar no banco perto da fonte.',
    'revelado no primeiro dia',
    Icons.graphic_eq,
  ),
  Lugar(
    'Biblioteca Velha',
    'A Frost vem aqui reler o que você escreveu no diário. É o lugar '
        'mais silencioso da cidade.',
    'revelado ao guardar a primeira memória',
    Icons.local_library_outlined,
  ),
  Lugar(
    'Café da Esquina',
    'Apareceu no mapa quando você passou por um café de verdade. Tem '
        'sempre algum NAVI novo por lá.',
    'revelado pela sua localização',
    Icons.local_cafe_outlined,
  ),
];

class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  void _abrir(BuildContext context, Lugar lugar) {
    debugPrint('[Cidade] pushNamed(${Rotas.lugar}, arguments: ${lugar.nome})');
    Navigator.pushNamed(context, Rotas.lugar, arguments: lugar);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Cidade'),
        const TituloGrande('Cidade', subtitulo: 'lugares que a Frost conhece'),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: lugares.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final lugar = lugares[i];
              return _CartaoLista(
                icone: lugar.icone,
                titulo: lugar.nome,
                subtitulo: lugar.comoRevelou,
                onTap: () => _abrir(context, lugar),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recebe o Lugar pelos arguments da rota nomeada.
class LugarScreen extends StatelessWidget {
  final Lugar lugar;

  const LugarScreen({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoDetalhe('Cidade / ${lugar.nome}'),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFF211B3A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF493A70)),
              ),
              child: Icon(lugar.icone, color: kPurple, size: 42),
            ),
          ),
          TituloGrande(lugar.nome, subtitulo: lugar.comoRevelou),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              lugar.descricao,
              style: const TextStyle(
                color: Color(0xFFC5C1CB),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENCONTROS (aba com pilha: lista -> NAVI -> apelido)
// ============================================================

class NaviEncontrado {
  final String nome;
  final int afinidade; // 0 a 100
  final String quando;
  final String relato;
  final Color cor;
  String? apelido;

  NaviEncontrado(
    this.nome,
    this.afinidade,
    this.quando,
    this.relato,
    this.cor,
  );

  String get comoChamar => apelido ?? nome;
}

/// Estado global compartilhado entre a lista de Encontros e a tela de detalhes.
/// A lógica de alteração dos apelidos fica fora dos widgets.
class EstadoCodice extends ChangeNotifier {
  final List<NaviEncontrado> _navis = [
    NaviEncontrado(
      'Pixel',
      72,
      'hoje, 14:20 · Praça dos Bipes',
      'Pixel fala rápido e repete os bipes de três em três. A Frost achou '
          'engraçado e quer encontrar de novo.',
      const Color(0xFF6CEFF1),
    ),
    NaviEncontrado(
      'Bolota',
      45,
      'ontem, 19:05 · Café da Esquina',
      'Bolota ficou quieto quase o encontro todo. A Frost acha que ele é '
          'tímido, não chato.',
      const Color(0xFFFFB86B),
    ),
    NaviEncontrado(
      'Nimbus',
      88,
      'segunda, 08:40 · Biblioteca Velha',
      'Nimbus também gosta de ler. Os dois trocaram bipes longos, que no '
          'Navidês é sinal de amizade.',
      kPurple,
    ),
  ];

  List<NaviEncontrado> get navis => List.unmodifiable(_navis);

  NaviEncontrado? obterNavi(String nome) {
    for (final navi in _navis) {
      if (navi.nome == nome) return navi;
    }
    return null;
  }

  void alterarApelido(String nome, String novoApelido) {
    final navi = obterNavi(nome);
    if (navi == null || novoApelido.trim().isEmpty) return;

    navi.apelido = novoApelido.trim();
    notifyListeners();
  }
}

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  Future<void> _abrir(NaviEncontrado navi) async {
    debugPrint('[Encontros] pushNamed(${Rotas.naviEncontrado}, '
        'arguments: ${navi.nome})');
    await Navigator.pushNamed(context, Rotas.naviEncontrado, arguments: navi);
    // A lista é atualizada automaticamente pelo EstadoCodice/Provider.
  }

  @override
  Widget build(BuildContext context) {
    final navis = context.watch<EstadoCodice>().navis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoAba('Encontros'),
        const TituloGrande(
          'Encontros',
          subtitulo: 'NAVIs que a Frost conheceu por perto',
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: navis.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final navi = navis[i];
              return _CartaoLista(
                icone: Icons.smart_toy_outlined,
                corIcone: navi.cor,
                titulo: navi.apelido == null
                    ? navi.nome
                    : '${navi.apelido}  (${navi.nome})',
                subtitulo: '${navi.quando} · afinidade ${navi.afinidade}%',
                onTap: () => _abrir(navi),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recebe o NaviEncontrado pelos arguments da rota nomeada.
class NaviScreen extends StatefulWidget {
  final NaviEncontrado navi;

  const NaviScreen({super.key, required this.navi});

  @override
  State<NaviScreen> createState() => _NaviScreenState();
}

class _NaviScreenState extends State<NaviScreen> {
  /// Empilha mais uma tela NA MESMA ABA e espera o resultado do pop.
  Future<void> _darApelido() async {
    final navi = widget.navi;
    debugPrint('[Encontros] pushNamed<String>(${Rotas.apelido}, '
        'arguments: "${navi.comoChamar}")');
    final novo = await Navigator.pushNamed<String>(
      context,
      Rotas.apelido,
      arguments: navi.comoChamar,
    );
    debugPrint('[Encontros] ApelidoScreen devolveu: '
        '${novo == null ? 'nada (cancelou)' : '"$novo"'}');
    if (!mounted || novo == null || novo.isEmpty) return;
    context.read<EstadoCodice>().alterarApelido(navi.nome, novo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('a Frost agora chama ${navi.nome} de "$novo"'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoCodice>();
    final navi = estado.obterNavi(widget.navi.nome) ?? widget.navi;
    return Material(
      color: kBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabecalhoDetalhe('Encontros / ${navi.nome}'),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B3A),
                  shape: BoxShape.circle,
                  border: Border.all(color: navi.cor),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: navi.cor,
                  size: 46,
                ),
              ),
            ),
            TituloGrande(
              navi.comoChamar,
              subtitulo: navi.apelido == null
                  ? navi.quando
                  : 'apelido de ${navi.nome} · ${navi.quando}',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'afinidade ${navi.afinidade}%',
                    style: const TextStyle(color: kPurple2, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: navi.afinidade / 100,
                      minHeight: 6,
                      color: navi.cor,
                      backgroundColor: const Color(0xFF2A2735),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '«${navi.relato}»',
                    style: const TextStyle(
                      color: Color(0xFFC5C1CB),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _darApelido,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        navi.apelido == null
                            ? 'dar um apelido'
                            : 'mudar apelido',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: const Color(0xFF0D0B13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recebe o apelido atual e devolve o novo com Navigator.pop(valor).
/// Cancelar (ou o voltar do sistema) devolve null.
class ApelidoScreen extends StatefulWidget {
  final String apelidoAtual;

  const ApelidoScreen({super.key, required this.apelidoAtual});

  @override
  State<ApelidoScreen> createState() => _ApelidoScreenState();
}

class _ApelidoScreenState extends State<ApelidoScreen> {
  static const List<String> sugestoes = ['Bipinho', 'Faísca', 'Nuvenzinha'];

  late final TextEditingController _campo =
      TextEditingController(text: widget.apelidoAtual);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final apelido = _campo.text.trim();
    debugPrint('[Apelido] Navigator.pop(context, "$apelido")');
    Navigator.pop(context, apelido);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabecalhoDetalhe('Encontros / apelido'),
            const TituloGrande(
              'Dar um apelido',
              subtitulo: 'a Frost vai usar esse nome quando falar dele.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _campo,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _salvar(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kPanel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in sugestoes)
                        ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          onPressed: () => _campo.text = s,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: const Color(0xFF0D0B13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('salvar apelido'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      debugPrint('[Apelido] Navigator.pop(context) sem valor');
                      Navigator.pop(context);
                    },
                    child: const Text('cancelar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha clicável das listas de Cidade e Encontros.
class _CartaoLista extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _CartaoLista({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.corIcone = kPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1924),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Color(0xFF302D3B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icone, color: corIcone),
        title: Text(
          titulo,
          style: const TextStyle(color: Color(0xFFE4E0E9), fontSize: 13),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(color: Color(0xFF8B8498), fontSize: 10),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8B8498)),
      ),
    );
  }
}

// ============================================================
// BARRA INFERIOR
// ============================================================

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLine, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kBottom,
        elevation: 0,
        iconSize: 17,
        selectedItemColor: kPurple,
        unselectedItemColor: const Color(0xFF898494),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          for (final aba in abas)
            BottomNavigationBarItem(
              icon: Icon(aba.icone),
              // A "pílula" atrás do ícone da aba selecionada.
              activeIcon: Container(
                width: 27,
                height: 23,
                decoration: BoxDecoration(
                  color: const Color(0xFF251B4B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(aba.icone),
              ),
              label: aba.nome,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CÍRCULOS DO CHÃO
// ============================================================

/// Qual metade dos anéis desenhar. A de trás fica atrás da Frost e a da
/// frente passa na frente dela: é isso que dá a sensação de chão.
enum MetadeDoChao { tras, frente }

class GroundCirclesPainter extends CustomPainter {
  final MetadeDoChao metade;

  const GroundCirclesPainter({required this.metade});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6CEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final centro = Offset(size.width / 2, size.height / 2);

    // Arco de cima (π → 2π) é o fundo; o de baixo (0 → π) é a frente.
    final inicio = metade == MetadeDoChao.tras ? math.pi : 0.0;

    // Largura em fração do palco, altura fixa: anéis concêntricos.
    const aneis = [(0.74, 26.0), (0.54, 19.0), (0.34, 12.0)];
    for (final (largura, altura) in aneis) {
      canvas.drawArc(
        Rect.fromCenter(
          center: centro,
          width: size.width * largura,
          height: altura,
        ),
        inicio,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GroundCirclesPainter oldDelegate) =>
      oldDelegate.metade != metade;
}
