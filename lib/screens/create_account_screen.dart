import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Tela de criar conta do app Nikeon
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
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // Chave para o formulário (para validação)
  final _formKey = GlobalKey<FormState>();
  
  // Serviço de autenticação
  final _authService = AuthService();
  
  // Estado de carregamento
  bool _isLoading = false;
  
  // Estado para verificação de email
  bool _isCheckingEmail = false;
  bool? _emailAvailable;
  bool? _isEmailFormatValid;
  Timer? _emailCheckTimer;
  
  // Estado para requisitos de senha
  bool _hasMinLength = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  
  // Estado para validação de confirmar senha
  bool? _passwordsMatch;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Valida o formato básico do email
  bool _isEmailFormatValidInternal(String email) {
    final normalized = email.trim();
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return normalized.isNotEmpty && regex.hasMatch(normalized);
  }

  /// Verifica disponibilidade do email com debounce
  void _onEmailChanged() {
    final email = _emailController.text.trim();

    final formatValid = _isEmailFormatValidInternal(email);
    setState(() {
      _isEmailFormatValid = email.isEmpty ? null : formatValid;
    });
    
    // Cancela o timer anterior
    _emailCheckTimer?.cancel();
    
    // Limpa o estado se o email estiver vazio ou com formato inválido
    if (email.isEmpty || !formatValid) {
      setState(() {
        _emailAvailable = null;
        _isCheckingEmail = false;
      });
      return;
    }
    
    // Define um timer de 400ms (debounce)
    _emailCheckTimer = Timer(const Duration(milliseconds: 400), () {
      _checkEmailAvailability(email);
    });
  }

  /// Verifica se o email está disponível
  Future<void> _checkEmailAvailability(String email) async {
    if (!mounted) return;
    
    // Normaliza o email antes de verificar
    final normalizedEmail = email.trim().toLowerCase();
    
    // Valida formato básico
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      if (mounted) {
        setState(() {
          _emailAvailable = null;
          _isCheckingEmail = false;
        });
      }
      return;
    }
    
    setState(() {
      _isCheckingEmail = true;
      _emailAvailable = null;
    });

    try {
      // checkEmailExists retorna true se o email JÁ existe (indisponível)
      // retorna false se o email NÃO existe (disponível)
      final exists = await _authService.checkEmailExists(normalizedEmail);
      
      if (mounted) {
        setState(() {
          // Se exists = true → email já cadastrado → _emailAvailable = false (indisponível)
          // Se exists = false → email não cadastrado → _emailAvailable = true (disponível)
          _emailAvailable = !exists;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailAvailable = null;
          _isCheckingEmail = false;
        });
      }
    }
  }

  /// Atualiza os requisitos de senha em tempo real
  void _onPasswordChanged() {
    final password = _passwordController.text;
    
    setState(() {
      _hasMinLength = password.length >= 6;
      _hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      
      // Atualiza também a validação de confirmar senha se já houver texto
      if (_confirmPasswordController.text.isNotEmpty) {
        _passwordsMatch = _confirmPasswordController.text == password;
      }
    });
  }

  /// Atualiza a validação de confirmar senha em tempo real
  void _onConfirmPasswordChanged() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    
    setState(() {
      if (confirmPassword.isEmpty) {
        _passwordsMatch = null;
      } else {
        _passwordsMatch = confirmPassword == password;
      }
    });
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
      // Trata erros de forma amigável
      if (mounted) {
        String errorMessage = 'Erro ao criar conta. Tente novamente.';
        
        // Verifica se é erro de email já existente
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('already registered') ||
            errorString.contains('user already registered') ||
            errorString.contains('email') && errorString.contains('already')) {
          errorMessage = 'Este email já está cadastrado. Tente outro ou faça login.';
        } else if (errorString.contains('password')) {
          errorMessage = 'A senha não atende aos requisitos. Verifique e tente novamente.';
          _passwordFocusNode.requestFocus();
        }
        
        // Exibe mensagem amigável
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
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
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
                          
                          // Campo de email com feedback de disponibilidade
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  if (_emailAvailable == false) {
                                    return 'Este email já está em uso';
                                  }
                                  return null;
                                },
                              ),
                              // Feedback de disponibilidade do email
                              if (_emailController.text.isNotEmpty && _emailController.text.contains('@'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                  child: _buildEmailAvailabilityFeedback(),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Campo de senha com requisitos
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  if (!_hasMinLength) {
                                    return 'Senha deve ter pelo menos 6 caracteres';
                                  }
                                  if (!_hasLetter) {
                                    return 'Senha deve conter pelo menos uma letra';
                                  }
                                  if (!_hasNumber) {
                                    return 'Senha deve conter pelo menos um número';
                                  }
                                  return null;
                                },
                              ),
                              // Lista de requisitos de senha
                              if (_passwordController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                  child: _buildPasswordRequirements(),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Campo de confirmar senha com feedback
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NeonTextField(
                                label: 'Confirmar Senha',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                showPasswordToggle: true,
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
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
                              // Feedback de correspondência de senhas
                              if (_confirmPasswordController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                  child: _buildPasswordMatchFeedback(),
                                ),
                            ],
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

  /// Constrói o feedback de disponibilidade do email
  Widget _buildEmailAvailabilityFeedback() {
    if (_isEmailFormatValid == false) {
      return Row(
        children: [
          Icon(
            Icons.cancel,
            size: 14,
            color: NeonTheme.pink,
          ),
          const SizedBox(width: 6),
          Text(
            'Formato de email inválido',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.pink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_isCheckingEmail) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: NeonTheme.teal,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Verificando...',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    if (_emailAvailable == true) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: NeonTheme.green,
          ),
          const SizedBox(width: 6),
          Text(
            'Email disponível',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_emailAvailable == false) {
      return Row(
        children: [
          Icon(
            Icons.cancel,
            size: 14,
            color: NeonTheme.pink,
          ),
          const SizedBox(width: 6),
          Text(
            'Este email já está em uso',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.pink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Constrói a lista de requisitos de senha
  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementItem(
          'Mínimo de 6 caracteres',
          _hasMinLength,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          'Pelo menos uma letra',
          _hasLetter,
        ),
        const SizedBox(height: 4),
        _buildRequirementItem(
          'Pelo menos um número',
          _hasNumber,
        ),
      ],
    );
  }

  /// Constrói um item de requisito de senha
  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle,
          size: 14,
          color: isMet ? NeonTheme.green : NeonTheme.textSecondary.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? NeonTheme.green : NeonTheme.textSecondary,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Constrói o feedback de correspondência de senhas
  Widget _buildPasswordMatchFeedback() {
    if (_passwordsMatch == null) {
      return const SizedBox.shrink();
    }

    if (_passwordsMatch == true) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: NeonTheme.green,
          ),
          const SizedBox(width: 6),
          Text(
            'As senhas coincidem',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // _passwordsMatch == false
    return Row(
      children: [
        Icon(
          Icons.cancel,
          size: 14,
          color: NeonTheme.pink,
        ),
        const SizedBox(width: 6),
        Text(
          'As senhas não são iguais',
          style: TextStyle(
            fontSize: 12,
            color: NeonTheme.pink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
