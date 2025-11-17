import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de autenticação do app Arkion
/// 
/// Centraliza toda a lógica de autenticação usando Supabase.
/// Gerencia criação de usuários, login, logout e recuperação de perfil.
class AuthService {
  // Cliente Supabase global
  final _supabase = Supabase.instance.client;

  /// Cria um novo usuário no Supabase Auth
  /// 
  /// Após criar o usuário, também cria um perfil na tabela "profiles"
  /// com id, name e email.
  /// 
  /// Retorna o usuário criado ou lança uma exceção em caso de erro.
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Cria o usuário no Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Verifica se o usuário foi criado com sucesso
      if (response.user == null) {
        throw Exception('Falha ao criar usuário');
      }

      // Cria o perfil na tabela "profiles"
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
      });

      return response.user!;
    } catch (e) {
      // Re-lança a exceção com uma mensagem mais clara
      throw Exception('Erro ao criar conta: ${e.toString()}');
    }
  }

  /// Autentica um usuário existente
  /// 
  /// Faz login com email e senha, e carrega o perfil do usuário
  /// da tabela "profiles".
  /// 
  /// Retorna o usuário autenticado ou lança uma exceção em caso de erro.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Autentica o usuário
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verifica se a autenticação foi bem-sucedida
      if (response.user == null) {
        throw Exception('Falha ao fazer login');
      }

      return response.user!;
    } catch (e) {
      // Re-lança a exceção com uma mensagem mais clara
      throw Exception('Erro ao fazer login: ${e.toString()}');
    }
  }

  /// Faz logout do usuário atual
  /// 
  /// Remove a sessão do Supabase Auth.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: ${e.toString()}');
    }
  }

  /// Retorna o usuário atual autenticado
  /// 
  /// Retorna null se não houver usuário logado.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Carrega o perfil do usuário atual da tabela "profiles"
  /// 
  /// Retorna um Map com os dados do perfil (id, name, email)
  /// ou null se o usuário não estiver logado ou não tiver perfil.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      // Se o perfil não existir, retorna null
      return null;
    }
  }

  /// Verifica se há uma sessão ativa
  /// 
  /// Retorna true se o usuário estiver autenticado.
  bool isAuthenticated() {
    return getCurrentUser() != null;
  }
}

