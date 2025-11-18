import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Medalha neon para exibir posições no ranking
/// 
/// Componente reutilizável que exibe uma medalha circular com cores
/// e ícones diferentes baseados na posição do jogador.
class RankingMedal extends StatelessWidget {
  /// Posição no ranking (1, 2, 3 ou outras)
  final int position;

  const RankingMedal({
    super.key,
    required this.position,
  });

  /// Retorna a cor da medalha baseada na posição
  Color _getMedalColor() {
    switch (position) {
      case 1:
        // Ouro neon
        return const Color(0xFFFFD700);
      case 2:
        // Teal (prata)
        return NeonTheme.teal;
      case 3:
        // Rosa (bronze)
        return NeonTheme.pink;
      default:
        // Branco translúcido
        return Colors.white.withOpacity(0.3);
    }
  }

  /// Retorna o ícone baseado na posição
  IconData _getMedalIcon() {
    switch (position) {
      case 1:
        return Icons.emoji_events;
      case 2:
      case 3:
        return Icons.emoji_events_outlined;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final medalColor = _getMedalColor();
    final medalIcon = _getMedalIcon();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medalColor.withOpacity(0.2),
        border: Border.all(
          color: medalColor.withOpacity(0.6),
          width: 2,
        ),
        // Glow neon
        boxShadow: [
          BoxShadow(
            color: medalColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: medalColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        medalIcon,
        color: medalColor,
        size: 24,
      ),
    );
  }
}

