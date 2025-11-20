import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_text_field.dart';
import '../services/auth_service.dart';
import 'create_account_screen.dart';
import 'home_screen.dart';

/// Tela de login do app Arkion
/// 
/// Permite que o usuário faça login com email e senha.
/// Mantém o mesmo estilo visual neon gamer premium da tela de boas-vindas.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para os campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  
  // Chave para o formulário (para validação)
  final _formKey = GlobalKey<FormState>();
  
  // Serviço de autenticação
  final _authService = AuthService();
  
  // Estado de carregamento
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Valida e processa o login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Faz login usando o AuthService
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Se o login for bem-sucedido, navega para a HomeScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Mostra mensagem de erro amigável
      if (mounted) {
        // Foca novamente no campo de senha
        _passwordFocusNode.requestFocus();
        
        // Exibe mensagem amigável e elegante
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: NeonTheme.pink,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Email ou senha incorretos. Tente novamente.',
                    style: TextStyle(
                      color: NeonTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: NeonTheme.pink.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navega para a tela de criar conta
  void _navigateToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateAccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aplica o gradiente de fundo (mesmo da tela de boas-vindas)
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeonTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Botão de voltar no topo esquerdo
                _buildBackButton(),
                
                // Conteúdo centralizado
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Título
                          const Text(
                            'Login',
                            style: NeonTheme.titleStyle,
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Subtítulo
                          const Text(
                            'Acesse sua conta para continuar.',
                            style: NeonTheme.subtitleStyle,
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Campo de email
                          NeonTextField(
                            label: 'Email',
                            icon: Icons.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu email';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Campo de senha
                          NeonTextField(
                            label: 'Senha',
                            icon: Icons.lock,
                            obscureText: true,
                            showPasswordToggle: true,
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira sua senha';
                              }
                              if (value.length < 6) {
                                return 'Senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Botão primário "Entrar"
                          NeonButton.primary(
                            text: _isLoading ? 'Entrando...' : 'Entrar',
                            onPressed: _isLoading ? null : _handleLogin,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão secundário "Criar conta" (texto neon)
                          TextButton(
                            onPressed: _navigateToCreateAccount,
                            child: Text(
                              'Criar conta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NeonTheme.pink,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o botão de voltar no topo esquerdo
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: NeonTheme.teal.withOpacity(0.4),
              width: 1.5,
            ),
            // Brilho sutil
            boxShadow: [
              BoxShadow(
                color: NeonTheme.teal.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: NeonTheme.teal,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

