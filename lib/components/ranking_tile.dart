import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../models/ranking_entry.dart';
import 'ranking_medal.dart';

/// Tile de ranking com tema neon
/// 
/// Componente reutilizável para exibir informações de um jogador
/// no ranking global. Inclui medalha, avatar, estatísticas e score.
class RankingTile extends StatelessWidget {
  /// Entrada do ranking com os dados do jogador
  final RankingEntry entry;

  const RankingTile({
    super.key,
    required this.entry,
  });

  /// Retorna a inicial do nome do jogador
  String _getInitial() {
    final name = entry.username ?? '?';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  /// Retorna a cor do avatar baseada na posição
  Color _getAvatarColor() {
    switch (entry.position) {
      case 1:
        return const Color(0xFFFFD700).withOpacity(0.3);
      case 2:
        return NeonTheme.teal.withOpacity(0.3);
      case 3:
        return NeonTheme.pink.withOpacity(0.3);
      default:
        return NeonTheme.textSecondary.withOpacity(0.2);
    }
  }

  /// Retorna a cor da borda do avatar baseada na posição
  Color _getAvatarBorderColor() {
    switch (entry.position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return NeonTheme.teal;
      case 3:
        return NeonTheme.pink;
      default:
        return NeonTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.teal.withOpacity(0.3),
          width: 1.5,
        ),
        // Brilho sutil neon
        boxShadow: [
          BoxShadow(
            color: NeonTheme.teal.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Medalha de posição
          RankingMedal(position: entry.position),
          const SizedBox(width: 16),
          // Avatar com inicial
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(),
              border: Border.all(
                color: _getAvatarBorderColor().withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _getInitial(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getAvatarBorderColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Informações do jogador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do jogador
                Text(
                  entry.username ?? 'Jogador',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Estatísticas (vitórias e derrotas)
                Row(
                  children: [
                    // Vitórias
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: NeonTheme.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.wins}',
                          style: TextStyle(
                            fontSize: 12,
                            color: NeonTheme.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Derrotas
                    Row(
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 14,
                          color: NeonTheme.pink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.losses}',
                          style: TextStyle(
                            fontSize: 12,
                            color: NeonTheme.pink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score alinhado à direita
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.teal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'pontos',
                style: TextStyle(
                  fontSize: 10,
                  color: NeonTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

