import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Card de estatística com tema neon
/// 
/// Componente reutilizável para exibir estatísticas no dashboard.
/// Usa cores neon (teal ou magenta) com brilho sutil.
class NeonStatCard extends StatelessWidget {
  /// Título do card (ex: "Partidas jogadas")
  final String title;
  
  /// Valor a ser exibido (ex: "42")
  final String value;
  
  /// Cor neon a ser usada (teal ou magenta)
  final Color accentColor;
  
  /// Ícone opcional para o card
  final IconData? icon;

  const NeonStatCard({
    super.key,
    required this.title,
    required this.value,
    this.accentColor = NeonTheme.teal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.4),
          width: 1.5,
        ),
        // Brilho sutil neon
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha superior com ícone e título
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NeonTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Valor em destaque
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

