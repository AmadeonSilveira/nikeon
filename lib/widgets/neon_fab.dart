import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// FAB neon para registrar nova partida.
class NeonFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const NeonFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 8), // Move o botão 8px para dentro do navbar
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56, // Reduzido de 70 para 56
          height: 56, // Reduzido de 70 para 56
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeonTheme.teal,
                NeonTheme.green.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18), // Ajustado proporcionalmente
            boxShadow: [
              BoxShadow(
                color: NeonTheme.teal.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: NeonTheme.green.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 26, // Reduzido de 32 para 26
            ),
          ),
        ),
      ),
    );
  }
}

