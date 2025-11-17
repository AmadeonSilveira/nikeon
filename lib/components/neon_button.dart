import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Botão neon reutilizável com gradiente e efeito de brilho
/// 
/// Este componente cria botões com visual neon usando gradientes
/// e sombras para dar o efeito de brilho característico.
class NeonButton extends StatelessWidget {
  /// Texto exibido no botão
  final String text;
  
  /// Gradiente aplicado ao botão
  final LinearGradient gradient;
  
  /// Função chamada quando o botão é pressionado
  final VoidCallback? onPressed;
  
  /// Largura do botão (opcional, padrão ocupa toda largura disponível)
  final double? width;
  
  /// Altura do botão (opcional, padrão 56)
  final double? height;

  const NeonButton({
    super.key,
    required this.text,
    required this.gradient,
    this.onPressed,
    this.width,
    this.height,
  });

  /// Cria um botão primário (teal → green)
  factory NeonButton.primary({
    required String text,
    VoidCallback? onPressed,
    double? width,
    double? height,
  }) {
    return NeonButton(
      text: text,
      gradient: NeonTheme.primaryButtonGradient,
      onPressed: onPressed,
      width: width,
      height: height,
    );
  }

  /// Cria um botão secundário (pink → magenta)
  factory NeonButton.secondary({
    required String text,
    VoidCallback? onPressed,
    double? width,
    double? height,
  }) {
    return NeonButton(
      text: text,
      gradient: NeonTheme.secondaryButtonGradient,
      onPressed: onPressed,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Opacidade reduzida quando o botão está desabilitado
    final opacity = onPressed == null ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height ?? 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          // Sombra externa reduzida para visual mais sofisticado
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: gradient.colors.last.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Borda sutil para definição
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  text,
                  style: NeonTheme.buttonTextStyle.copyWith(
                    // Texto com sombra sutil para melhor contraste e legibilidade
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

