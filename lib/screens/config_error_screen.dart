import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Tela de erro de configuração
/// 
/// Exibida quando há problemas ao inicializar o aplicativo,
/// como falha ao carregar as variáveis de ambiente ou inicializar o Supabase.
class ConfigErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ConfigErrorScreen({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // Ícone de erro
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeonTheme.pink.withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NeonTheme.pink.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 40,
                      color: NeonTheme.pink,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Título
                  const Text(
                    'Erro de Configuração',
                    style: NeonTheme.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mensagem de erro
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: NeonTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Informações adicionais
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NeonTheme.teal.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: NeonTheme.teal,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Como resolver:',
                              style: TextStyle(
                                color: NeonTheme.teal,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Verifique se o arquivo .env existe na raiz do projeto\n'
                          '2. Certifique-se de que contém SUPABASE_URL e SUPABASE_ANON_KEY\n'
                          '3. Reconstrua o APK após corrigir o problema',
                          style: TextStyle(
                            color: NeonTheme.textSecondary,
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
