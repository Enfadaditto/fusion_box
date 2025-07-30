import 'package:flutter/material.dart';

class DebugIcon extends StatelessWidget {
  const DebugIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Debug'),
                // Swap this content with the widget you want to debug
                content: Text('TODO: Generar el widget de selector de variables de una fusion'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      },
      icon: Icon(Icons.bug_report),
    );
  }
}
