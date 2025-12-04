import 'package:flutter/material.dart';

/// Tema Neon Gamer Premium para o app Nikeon
/// 
/// Este arquivo contém todas as cores, gradientes e estilos de texto
/// com tema neon para manter consistência visual em todo o app.
class NeonTheme {
  // Cores base do tema neon
  // Cores teal/cyan para elementos primários
  static const Color teal = Color(0xFF00D4FF);
  static const Color tealDark = Color(0xFF00A8CC);
  static const Color green = Color(0xFF00FF88);
  static const Color greenDark = Color(0xFF00CC6A);
  
  // Cores pink/magenta para elementos secundários
  static const Color pink = Color(0xFFFF00AA);
  static const Color pinkDark = Color(0xFFCC0088);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color magentaDark = Color(0xFFCC00CC);
  
  // Cores de fundo
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundDarker = Color(0xFF050508);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  /// Gradiente de fundo principal (teal → magenta)
  /// Usado na tela de boas-vindas - versão mais suave e sutil
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E15), // Preto azulado muito escuro
      Color(0xFF0F0A15), // Preto arroxeado muito escuro
      Color(0xFF0A0A0F), // Preto puro
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  /// Gradiente para botão primário (teal → green)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      teal,
      green,
    ],
  );
  
  /// Gradiente para botão secundário (pink → magenta)
  static const LinearGradient secondaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      pink,
      magenta,
    ],
  );
  
  /// Estilo de texto para títulos principais
  /// Brilho reduzido para um visual mais sofisticado
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.0,
    shadows: [
      Shadow(
        color: Color(0x4000D4FF), // teal com 25% de opacidade
        blurRadius: 8,
      ),
      Shadow(
        color: Color(0x2000D4FF), // teal com 12.5% de opacidade
        blurRadius: 12,
      ),
    ],
  );
  
  /// Estilo de texto para subtítulos
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.5,
  );
  
  /// Estilo de texto para botões
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.0,
  );
}

