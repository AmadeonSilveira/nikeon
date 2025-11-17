import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Tela de criar conta do app Arkion
/// 
/// Permite que o usuário crie uma nova conta com nome, email e senha.
/// Mantém o mesmo estilo visual neon gamer premium das outras telas.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // Controladores para os campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Chave para o formulário (para validação)
  final _formKey = GlobalKey<FormState>();
  
  // Serviço de autenticação
  final _authService = AuthService();
  
  // Estado de carregamento
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valida e processa o cadastro
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cria a conta usando o AuthService
      await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Se o cadastro for bem-sucedido, navega para a HomeScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Mostra mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  /// Navega para a tela de login
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aplica o gradiente de fundo (mesmo das outras telas)
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
                            'Criar Conta',
                            style: NeonTheme.titleStyle,
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Subtítulo
                          const Text(
                            'Crie sua conta para começar.',
                            style: NeonTheme.subtitleStyle,
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Campo de nome
                          NeonTextField(
                            label: 'Nome',
                            icon: Icons.person,
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu nome';
                              }
                              if (value.length < 2) {
                                return 'Nome deve ter pelo menos 2 caracteres';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
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
                            controller: _passwordController,
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
                          
                          const SizedBox(height: 20),
                          
                          // Campo de confirmar senha
                          NeonTextField(
                            label: 'Confirmar Senha',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            controller: _confirmPasswordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, confirme sua senha';
                              }
                              if (value != _passwordController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Botão primário "Cadastrar"
                          NeonButton.secondary(
                            text: _isLoading ? 'Cadastrando...' : 'Cadastrar',
                            onPressed: _isLoading ? null : _handleSignUp,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão secundário "Já tenho conta" (texto neon)
                          TextButton(
                            onPressed: _navigateToLogin,
                            child: Text(
                              'Já tenho conta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NeonTheme.teal,
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
