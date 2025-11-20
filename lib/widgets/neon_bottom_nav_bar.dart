import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Barra inferior com notch central para o FAB neon.
class NeonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const NeonBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.68),
            Colors.black.withOpacity(0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: NeonTheme.teal.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.teal.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: NeonTheme.pink.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              index: 0,
              icon: Icons.videogame_asset_rounded,
              label: 'Jogos',
            ),
          ),
          const SizedBox(width: 100),
          Expanded(
            child: _buildTab(
              index: 1,
              icon: Icons.leaderboard_rounded,
              label: 'Ranking',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final iconColor = isSelected ? NeonTheme.green : NeonTheme.textSecondary;
    final textColor = iconColor;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 26,
            shadows: [
              Shadow(
                blurRadius: isSelected ? 10 : 0,
                color: iconColor.withOpacity(0.75),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

