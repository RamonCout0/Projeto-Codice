import 'package:flutter/material.dart';
import 'package:codice_app/ui/cores.dart';
import 'package:codice_app/widgets/menu.dart';
import 'package:codice_app/widgets/status_bar.dart';
import 'package:codice_app/ui/imagens.dart';

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
