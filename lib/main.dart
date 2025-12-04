import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/config_error_screen.dart';
import 'services/auth_service.dart';

/// Inicializa o Supabase antes de executar o app
/// 
/// As credenciais são carregadas do arquivo .env de forma segura.
/// 
/// SEGURANÇA:
/// - As credenciais estão no arquivo .env que está no .gitignore
/// - Use apenas a chave "anon" (anon public key) do Supabase
/// - NUNCA use a chave "service_role" no cliente - ela tem permissões totais
/// - A chave anon é segura porque respeita as políticas RLS do banco
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? errorMessage;

  try {
    // Tenta carregar as variáveis de ambiente do arquivo .env
    // O arquivo .env está no .gitignore e não deve ser commitado
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      errorMessage = 'Erro ao carregar arquivo .env: ${e.toString()}\n\n'
          'Certifique-se de que o arquivo .env existe na raiz do projeto '
          'e contém as variáveis SUPABASE_URL e SUPABASE_ANON_KEY.';
    }

    // Se não houve erro ao carregar o .env, tenta inicializar o Supabase
    if (errorMessage == null) {
      try {
        // Verifica se as variáveis estão configuradas
        if (!Env.isConfigured) {
          errorMessage = 'Variáveis de ambiente não configuradas.\n\n'
              'O arquivo .env deve conter:\n'
              'SUPABASE_URL=sua_url_aqui\n'
              'SUPABASE_ANON_KEY=sua_chave_aqui';
        } else {
          // Inicializa o Supabase com as credenciais do arquivo .env
          // As credenciais são acessadas através da classe Env para maior segurança
          await Supabase.initialize(
            url: Env.supabaseUrl,
            anonKey: Env.supabaseAnonKey,
          );
        }
      } catch (e) {
        errorMessage = 'Erro ao inicializar Supabase: ${e.toString()}\n\n'
            'Verifique se as credenciais no arquivo .env estão corretas.';
      }
    }
  } catch (e) {
    errorMessage = 'Erro inesperado ao inicializar o aplicativo: ${e.toString()}';
  }

  // Se houve erro, mostra a tela de erro. Caso contrário, inicia o app normalmente
  runApp(NikeonApp(errorMessage: errorMessage));
}

/// Widget raiz da aplicação Nikeon
/// 
/// Configura o MaterialApp e verifica se há sessão ativa.
/// Se o usuário estiver logado, vai direto para HomeScreen.
/// Caso contrário, mostra a WelcomeScreen.
/// Se houver erro de configuração, mostra a tela de erro.
class NikeonApp extends StatelessWidget {
  final String? errorMessage;

  const NikeonApp({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    // Se houver erro de configuração, mostra a tela de erro
    if (errorMessage != null) {
      return MaterialApp(
        title: 'Nikeon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: ConfigErrorScreen(errorMessage: errorMessage!),
      );
    }

    // Caso contrário, inicia o app normalmente
    final authService = AuthService();

    return MaterialApp(
      title: 'Nikeon',
      debugShowCheckedModeBanner: false,
      // Tema escuro como base para o tema neon
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // Verifica se há sessão ativa e define a tela inicial
      home: authService.isAuthenticated()
          ? const HomeScreen()
          : const WelcomeScreen(),
    );
  }
}
