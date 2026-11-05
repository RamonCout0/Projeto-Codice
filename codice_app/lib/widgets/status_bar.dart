import 'package:flutter/material.dart';

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
