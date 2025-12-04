import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../models/game.dart';

/// Card de jogo com tema neon
/// 
/// Componente reutilizável para exibir um jogo na lista de jogos.
/// Mostra thumbnail, nome e indicador de expansão se aplicável.
class GameCard extends StatelessWidget {
  /// Modelo Game com os dados do jogo
  final Game game;
  
  /// Nome do jogo base (se este for uma expansão)
  final String? parentGameName;
  
  /// Função chamada quando o card é pressionado
  final VoidCallback? onTap;
  
  /// Função chamada quando o botão de registrar partida é pressionado
  final VoidCallback? onRegisterMatch;

  const GameCard({
    super.key,
    required this.game,
    this.parentGameName,
    this.onTap,
    this.onRegisterMatch,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: game.isExpansion
                ? NeonTheme.magenta.withOpacity(0.4)
                : NeonTheme.teal.withOpacity(0.4),
            width: 1.5,
          ),
          // Brilho sutil neon
          boxShadow: [
            BoxShadow(
              color: (game.isExpansion ? NeonTheme.magenta : NeonTheme.teal)
                  .withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail do jogo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(
                  color: (game.isExpansion ? NeonTheme.magenta : NeonTheme.teal)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: game.imageUrl != null && game.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.network(
                        game.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon();
                        },
                      ),
                    )
                  : _buildPlaceholderIcon(),
            ),
            const SizedBox(width: 16),
            // Informações do jogo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do jogo
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: NeonTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Indicador de expansão
                    if (game.isExpansion && parentGameName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.extension,
                            size: 12,
                            color: NeonTheme.magenta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expansão de $parentGameName',
                            style: TextStyle(
                              fontSize: 12,
                              color: NeonTheme.magenta,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Informações adicionais
                    Row(
                      children: [
                        if (game.minPlayers != null || game.maxPlayers != null) ...[
                          Icon(
                            Icons.people,
                            size: 14,
                            color: NeonTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            game.playersString,
                            style: const TextStyle(
                              fontSize: 12,
                              color: NeonTheme.textSecondary,
                            ),
                          ),
                        ],
                        if ((game.minPlayers != null || game.maxPlayers != null) &&
                            game.playTimeMinutes != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: NeonTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            game.playTimeString,
                            style: const TextStyle(
                              fontSize: 12,
                              color: NeonTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botão de registro de partida (sempre visível)
            if (onRegisterMatch != null) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRegisterMatch,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeonTheme.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NeonTheme.teal.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: NeonTheme.teal,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Seta indicando que é clicável
            Icon(
              Icons.chevron_right,
              color: NeonTheme.textSecondary.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Constrói o ícone placeholder quando não há imagem
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.sports_esports,
        color: (game.isExpansion ? NeonTheme.magenta : NeonTheme.teal)
            .withOpacity(0.6),
        size: 32,
      ),
    );
  }
}

