import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// FAB neon para registrar nova partida.
class NeonFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const NeonFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              NeonTheme.teal,
              NeonTheme.green.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: NeonTheme.teal.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: NeonTheme.green.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

