import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Classe helper para acessar variáveis de ambiente de forma segura
/// 
/// Centraliza o acesso às variáveis de ambiente do arquivo .env,
/// fornecendo getters tipados e com validação.
/// 
/// SEGURANÇA:
/// - As credenciais são carregadas do arquivo .env que está no .gitignore
/// - Use apenas a chave "anon" (anon public key) do Supabase
/// - NUNCA use a chave "service_role" no cliente - ela tem permissões totais
/// - A chave anon é segura porque respeita as políticas RLS do banco
class Env {
  /// URL do projeto Supabase
  /// 
  /// Retorna a URL do Supabase configurada no arquivo .env.
  /// Lança uma exceção se a variável não estiver definida.
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL não está definida no arquivo .env. '
        'Verifique se o arquivo .env existe e contém SUPABASE_URL=your_url_here',
      );
    }
    return url;
  }

  /// Chave anônima pública do Supabase
  /// 
  /// Retorna a chave anon do Supabase configurada no arquivo .env.
  /// Esta é a chave pública segura para uso no cliente.
  /// 
  /// IMPORTANTE: Esta é a chave "anon" (anon public key), não a "service_role".
  /// A chave service_role NUNCA deve ser usada no cliente, pois tem permissões
  /// totais e ignora as políticas de segurança (RLS).
  /// 
  /// Lança uma exceção se a variável não estiver definida.
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY não está definida no arquivo .env. '
        'Verifique se o arquivo .env existe e contém SUPABASE_ANON_KEY=your_key_here',
      );
    }
    return key;
  }

  /// Verifica se as variáveis de ambiente necessárias estão configuradas
  /// 
  /// Retorna true se todas as variáveis obrigatórias estiverem definidas.
  static bool get isConfigured {
    return dotenv.env['SUPABASE_URL'] != null &&
        dotenv.env['SUPABASE_URL']!.isNotEmpty &&
        dotenv.env['SUPABASE_ANON_KEY'] != null &&
        dotenv.env['SUPABASE_ANON_KEY']!.isNotEmpty;
  }
}

