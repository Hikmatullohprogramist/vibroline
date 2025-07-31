import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final bool connected;
  final String status;
  const StatusPanel({super.key, required this.connected, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          connected ? Icons.check_circle : Icons.error,
          color: connected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
