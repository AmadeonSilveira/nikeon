import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
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

  // Carrega as variáveis de ambiente do arquivo .env
  // O arquivo .env está no .gitignore e não deve ser commitado
  await dotenv.load(fileName: '.env');

  // Inicializa o Supabase com as credenciais do arquivo .env
  // As credenciais são acessadas através da classe Env para maior segurança
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const NikeonApp());
}

/// Widget raiz da aplicação Nikeon
/// 
/// Configura o MaterialApp e verifica se há sessão ativa.
/// Se o usuário estiver logado, vai direto para HomeScreen.
/// Caso contrário, mostra a WelcomeScreen.
class NikeonApp extends StatelessWidget {
  const NikeonApp({super.key});

  @override
  Widget build(BuildContext context) {
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
