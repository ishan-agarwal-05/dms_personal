import 'package:flutter/material.dart';

class CommonCopyright extends StatelessWidget {
  const CommonCopyright({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          'Copyright © 2024 Techfour',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }
}