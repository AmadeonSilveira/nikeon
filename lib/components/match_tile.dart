import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../models/match.dart';

/// Tile de partida com tema neon
/// 
/// Componente reutilizável para exibir informações de uma partida
/// na lista de últimas partidas.
class MatchTile extends StatelessWidget {
  /// Modelo Match com os dados da partida
  final Match match;

  const MatchTile({
    super.key,
    required this.match,
  });

  /// Retorna a cor baseada no resultado
  Color _getResultColor() {
    if (match.isWin) {
      return NeonTheme.green;
    } else if (match.isLoss) {
      return NeonTheme.pink;
    }
    return NeonTheme.teal;
  }

  /// Retorna o ícone baseado no resultado
  IconData _getResultIcon() {
    if (match.isWin) {
      return Icons.emoji_events;
    } else if (match.isLoss) {
      return Icons.sentiment_dissatisfied;
    }
    return Icons.sports_esports;
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = _getResultColor();
    final resultIcon = _getResultIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resultColor.withOpacity(0.3),
          width: 1.5,
        ),
        // Brilho sutil baseado no resultado
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone do resultado
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: resultColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              resultIcon,
              color: resultColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Informações do jogo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.gameName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: resultColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      match.resultLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: resultColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      match.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NeonTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Seta indicando que é clicável
          Icon(
            Icons.chevron_right,
            color: NeonTheme.textSecondary.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}

