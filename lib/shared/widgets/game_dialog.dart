import 'package:flutter/material.dart';

class GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget>? actions;

  const GameDialog({
    Key? key,
    required this.title,
    required this.message,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: actions ??
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
    );
  }
}