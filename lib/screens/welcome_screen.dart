import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';

/// Tela de boas-vindas do app Nikeon
/// 
/// Exibe uma tela de apresentação com tema neon gamer premium,
/// incluindo logo, título, subtítulo e botões de ação.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aplica o gradiente de fundo
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeonTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo placeholder - container simples para logo futuro
                  _buildLogoPlaceholder(),
                  
                  const SizedBox(height: 36),
                  
                  // Título principal
                  const Text(
                    'Bem-vindo(a) ao Nikeon',
                    style: NeonTheme.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtítulo
                  const Text(
                    'Gerencie suas partidas de board game',
                    style: NeonTheme.subtitleStyle,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Botão primário "Entrar"
                  NeonButton.primary(
                    text: 'Entrar',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botão secundário "Criar conta"
                  NeonButton.secondary(
                    text: 'Criar conta',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o placeholder do logo
  /// 
  /// Por enquanto é apenas um container com borda neon.
  /// Pode ser substituído por uma imagem real no futuro.
  Widget _buildLogoPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12), // Border radius reduzido
        border: Border.all(
          color: NeonTheme.teal.withOpacity(0.6), // Borda mais sutil
          width: 2,
        ),
        // Sombra neon mais suave ao redor do logo
        boxShadow: [
          BoxShadow(
            color: NeonTheme.teal.withOpacity(0.2), // Opacidade reduzida
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports,
          size: 50,
          color: NeonTheme.teal.withOpacity(0.9), // Ícone ligeiramente mais suave
        ),
      ),
    );
  }
}

