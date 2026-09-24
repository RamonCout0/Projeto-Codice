import 'package:flutter/material.dart';

void main() {
  runApp(const CodiceApp());
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
// APP
// ============================================================

class CodiceApp extends StatelessWidget {
  const CodiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Códice',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
      ),
      home: const AppShell(),
    );
  }
}

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ConversationScreen(),
    DiaryScreen(),
    CityScreen(),
    MeetingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
            BottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
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
        Icon(
          Icons.signal_cellular_alt,
          size: 13,
          color: Colors.white,
        ),
        SizedBox(width: 4),
        Icon(
          Icons.wifi,
          size: 13,
          color: Colors.white,
        ),
        SizedBox(width: 4),
        Icon(
          Icons.battery_full,
          size: 16,
          color: Colors.white,
        ),
      ],
    );
  }
}

// ============================================================
// HEADER DE PÁGINA
// ============================================================

class PageHeader extends StatelessWidget {
  final String title;

  const PageHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D8996),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const StatusBar(),
      ],
    );
  }
}

// ============================================================
// TELA 1 — HOME
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const MobileHomeLayout();
        }

        return const DesktopHomeLayout();
      },
    );
  }
}

// ============================================================
// HOME MOBILE
// ============================================================

class MobileHomeLayout extends StatelessWidget {
  const MobileHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        13,
        5,
        13,
        15,
      ),
      child: Column(
        children: [
          const PageHeader(title: 'Home'),
          const SizedBox(height: 22),
          const ProfileHeader(),
          const SizedBox(height: 17),
          const NaviCard(),
          const SizedBox(height: 12),
          const QuestionCard(),
          const SizedBox(height: 10),
          const ActionButtons(),
          const SizedBox(height: 10),
          const VigorSection(),
        ],
      ),
    );
  }
}

// ============================================================
// HOME DESKTOP / TABLET
// ============================================================

class DesktopHomeLayout extends StatelessWidget {
  const DesktopHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        26,
        16,
        26,
        20,
      ),
      child: Column(
        children: [
          const PageHeader(title: 'Home'),
          const SizedBox(height: 24),
          const ProfileHeader(),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  flex: 6,
                  child: NaviCard(),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      QuestionCard(),
                      SizedBox(height: 12),
                      ActionButtons(),
                      SizedBox(height: 12),
                      VigorSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PERFIL
// ============================================================

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  Expanded(
                    child: _AgeBadge(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const FichaButton(),
            ],
          );
        }

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
            const SizedBox(width: 11),
            const Flexible(
              child: _AgeBadge(),
            ),
            const Spacer(),
            const FichaButton(),
          ],
        );
      },
    );
  }
}

class _AgeBadge extends StatelessWidget {
  const _AgeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF383345),
        ),
      ),
      child: const Text(
        '8 anos • criança',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFFB8B2C5),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FichaButton extends StatelessWidget {
  const FichaButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF211A3B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF45356F),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.face_retouching_natural,
            color: kPurple,
            size: 13,
          ),
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
    );
  }
}

// ============================================================
// NAVI CARD
// ============================================================

class NaviCard extends StatelessWidget {
  const NaviCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 342,
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF5A4B87),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: const RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 0.95,
                  colors: [
                    Color(0xFF192235),
                    Color(0xFF111624),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: NaviPlaceholder(),
          ),
          Positioned(
            left: 3,
            right: 3,
            bottom: 10,
            height: 40,
            child: CustomPaint(
              painter: GroundCirclesPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER DA NAVI
// ============================================================

class NaviPlaceholder extends StatelessWidget {
  const NaviPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 145,
          height: 145,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00C5C2),
            ),
            gradient: const RadialGradient(
              colors: [
                Color(0xFF283B57),
                Color(0xFF121A2B),
              ],
            ),
          ),
          child: const Icon(
            Icons.face_6,
            color: Color(0xFF9FE9EA),
            size: 80,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF00D4C1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 6,
                height: 6,
              ),
            ),
            SizedBox(width: 5),
            Text(
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
          'Se precisar de alguma ajuda,\nsó clicar em meu ícone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFC5C1CB),
            fontSize: 10,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// QUESTION CARD
// ============================================================

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        8,
        11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF36250D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5B411B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                color: Color(0xFFF0B74B),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ela quer entender uma coisa',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFF0B74B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0B74B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'resolver',
                  style: TextStyle(
                    color: Color(0xFF251A09),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            '«Você mudou de emprego?»',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'dois fatos que ela guarda se contradizem.',
            style: TextStyle(
              color: Color(0xFF918676),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION BUTTONS
// ============================================================

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) {
          return Column(
            children: [
              Row(
                children: const [
                  Expanded(
                    child: ActionButton(
                      icon: Icons.article_outlined,
                      label: 'escrever',
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.search,
                      label: 'lembrar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Expanded(
                    child: ActionButton(
                      icon: Icons.alarm,
                      label: 'alarme',
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.mic_none,
                      label: 'falar',
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: const [
            Expanded(
              child: ActionButton(
                icon: Icons.article_outlined,
                label: 'escrever',
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: ActionButton(
                icon: Icons.search,
                label: 'lembrar',
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: ActionButton(
                icon: Icons.alarm,
                label: 'alarme',
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: ActionButton(
                icon: Icons.mic_none,
                label: 'falar',
              ),
            ),
          ],
        );
      },
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 71,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: kLine,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: kPurple,
              size: 18,
            ),
            const SizedBox(height: 7),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB2ADBE),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VIGOR
// ============================================================

class VigorSection extends StatelessWidget {
  const VigorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'VIGOR',
            style: TextStyle(
              color: Color(0xFF8D879B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF65D6D6),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                '78',
                style: TextStyle(
                  color: Color(0xFFB9B3C3),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Center(
            child: Text(
              'descansou bem, sem desgaste acumulado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF777181),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA 2 — CONVERSA
// ============================================================

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState
    extends State<ConversationScreen> {
  bool listening = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                5,
                12,
                12,
              ),
              child: Column(
                children: [
                  const PageHeader(
                    title: 'Conversa com o NAVI',
                  ),
                  const SizedBox(height: 21),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Conversa',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF07382B),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color:
                                  Color(0xFF52D9A2),
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'off-line',
                              style: TextStyle(
                                color:
                                    Color(0xFF52D9A2),
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'hoje',
                    style: TextStyle(
                      color: Color(0xFF8C8798),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _message(
                    'oi. você dormiu mal a semana\ntoda — quer que eu te lembre?',
                    incoming: true,
                  ),
                  const SizedBox(height: 13),
                  _message(
                    'me acorda sete e meia',
                    incoming: false,
                  ),
                  const SizedBox(height: 13),
                  _message(
                    'marquei. bom descanso.',
                    incoming: true,
                  ),
                  const SizedBox(height: 12),
                  const ReminderCard(),
                  const SizedBox(height: 11),
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.only(left: 44),
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF171620),
                      borderRadius:
                          BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            const Color(0xFF302D3B),
                      ),
                    ),
                    child: const Text(
                      'a prova é quinta, né?',
                      style: TextStyle(
                        color:
                            Color(0xFFE1DEE7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const ListeningCard(),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 51,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF171620),
                    borderRadius:
                        BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          const Color(0xFF302D3B),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'escrever para a Frost...',
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Color(0xFF898394),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add,
                        color:
                            Color(0xFF9B96A4),
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    listening = !listening;
                  });
                },
                child: Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: listening
                        ? kPurple
                        : const Color(0xFF211B3A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: listening
                          ? kPurple
                          : const Color(0xFF4A3A76),
                    ),
                  ),
                  child: Icon(
                    listening
                        ? Icons.mic
                        : Icons.mic_none,
                    color:
                        const Color(0xFF171322),
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

  Widget _message(
    String text, {
    required bool incoming,
  }) {
    return Align(
      alignment: incoming
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        margin: incoming
            ? const EdgeInsets.only(right: 25)
            : const EdgeInsets.only(left: 40),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: incoming
              ? const Color(0xFF1A1924)
              : const Color(0xFF241D40),
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: incoming
                ? const Color(0xFF302D3B)
                : const Color(0xFF49396F),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: incoming
                ? const Color(0xFFE5E1EA)
                : Colors.white,
            fontSize: 12,
            fontWeight: incoming
                ? FontWeight.normal
                : FontWeight.bold,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 44),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF211F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF302D3B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4A27),
              borderRadius:
                  BorderRadius.circular(11),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  overflow:
                      TextOverflow.ellipsis,
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
    );
  }
}

class ListeningCard extends StatelessWidget {
  const ListeningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 79,
      padding: const EdgeInsets.fromLTRB(
        14,
        11,
        14,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF211B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A3A76),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'ouvindo...',
                style: TextStyle(
                  color: kPurple2,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Icon(
                Icons.verified_user_outlined,
                color: kPurple,
                size: 11,
              ),
              SizedBox(width: 4),
              Text(
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
          SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                for (final height in [
                  5.0,
                  12.0,
                  18.0,
                  10.0,
                  25.0,
                  12.0,
                  17.0,
                  9.0,
                  22.0,
                  27.0,
                  14.0,
                  22.0,
                  9.0,
                  16.0,
                  23.0,
                  13.0,
                  18.0,
                  11.0,
                  24.0,
                  16.0,
                ])
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7966C5),
                          borderRadius:
                              BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA 3 — DIÁRIO
// ============================================================

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() =>
      _DiaryScreenState();
}

class _DiaryScreenState
    extends State<DiaryScreen> {
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          17,
          5,
          17,
          15,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const PageHeader(title: 'Diário'),
            const SizedBox(height: 25),
            const Text(
              'Diário',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'quinta, 4 de setembro',
              style: TextStyle(
                color: Color(0xFF77727F),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                16,
                15,
                16,
                13,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1924),
                borderRadius:
                    BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFF302D3B),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acordei mal de novo, não preguei o olho.\n'
                    'A prova de física ficou pra quinta que vem,\n'
                    'o professor adiou na última hora — melhor,\n'
                    'porque eu não tinha estudado nada.\n'
                    'Almocei com a Bia, ela mudou de emprego\n'
                    'em março e eu nem sabia.',
                    style: TextStyle(
                      color:
                          Color(0xFFE4E0E9),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'continue escrevendo...',
                    style: TextStyle(
                      color:
                          Color(0xFF8B8498),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(
                    color: Color(0xFF2D2937),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    children: [
                      Text(
                        '64 palavras',
                        style: TextStyle(
                          color:
                              Color(0xFF888294),
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.mic_none,
                        color:
                            Color(0xFF8D8797),
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'ETIQUETAS SUGERIDAS',
              style: TextStyle(
                color: Color(0xFF8D879B),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                DiaryTag('prova'),
                DiaryTag('sono'),
                DiaryTag('Bia'),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    saved = true;
                  });
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor:
                      const Color(0xFF171322),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  saved
                      ? 'diário salvo ✓'
                      : 'guardar no diário',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryTag extends StatelessWidget {
  final String text;

  const DiaryTag(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF211F2B),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF373342),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFA8A1B4),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// TELA 4 — CIDADE
// ============================================================

class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePlaceholder(
      title: 'Cidade',
      subtitle: 'seu espaço na cidade',
      icon: Icons.account_balance_outlined,
    );
  }
}

// ============================================================
// TELA 5 — ENCONTROS
// ============================================================

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePlaceholder(
      title: 'Encontros',
      subtitle: 'pessoas e conexões',
      icon: Icons.people_outline,
    );
  }
}

// ============================================================
// PLACEHOLDER DAS TELAS SIMPLES
// ============================================================

class SimplePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const SimplePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            13,
            5,
            13,
            0,
          ),
          child: PageHeader(title: title),
        ),
        const SizedBox(height: 24),
        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 35),
        Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            color: const Color(0xFF211B3A),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF493A70),
            ),
          ),
          child: Icon(
            icon,
            color: kPurple,
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8B8595),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NAVEGAÇÃO INFERIOR
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 360;

        return Container(
          height: compact ? 62 : 68,
          decoration:
              const BoxDecoration(
            color: kBottom,
            border: Border(
              top: BorderSide(
                color: kLine,
              ),
            ),
          ),
          child: Row(
            children: [
              BottomNavItem(
                index: 0,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                icon:
                    Icons.sentiment_satisfied_alt_outlined,
                label: 'Navi',
                compact: compact,
              ),
              BottomNavItem(
                index: 1,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                icon:
                    Icons.chat_bubble_outline,
                label: 'Conversa',
                compact: compact,
              ),
              BottomNavItem(
                index: 2,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                icon: Icons.article_outlined,
                label: 'Diário',
                compact: compact,
              ),
              BottomNavItem(
                index: 3,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                icon:
                    Icons.account_balance_outlined,
                label: 'Cidade',
                compact: compact,
              ),
              BottomNavItem(
                index: 4,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                icon: Icons.people_outline,
                label: 'Encontros',
                compact: compact,
              ),
            ],
          ),
        );
      },
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final IconData icon;
  final String label;
  final bool compact;

  const BottomNavItem({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
    required this.icon,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 29,
              height: 23,
              decoration: selected
                  ? BoxDecoration(
                      color:
                          const Color(0xFF251B4B),
                      borderRadius:
                          BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                icon,
                size: compact ? 16 : 17,
                color: selected
                    ? kPurple
                    : const Color(0xFF8C8798),
              ),
            ),
            if (!compact)
              const SizedBox(height: 4),
            if (!compact)
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? kPurple
                        : const Color(0xFF898494),
                    fontSize: 9,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GROUND CIRCLES
// ============================================================

class GroundCirclesPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF6CEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width - 8,
        height: 23,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx,
          center.dy + 1,
        ),
        width: size.width * 0.74,
        height: 17,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx,
          center.dy + 1,
        ),
        width: size.width * 0.47,
        height: 11,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
