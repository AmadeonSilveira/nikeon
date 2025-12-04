import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import 'match_service.dart';

/// Serviço para gerenciar jogos no Supabase
/// 
/// Centraliza toda a lógica de CRUD de jogos, incluindo
/// busca de jogos base, expansões e sugestões baseadas em partidas.
class GameService {
  // Cliente Supabase global
  final _supabase = Supabase.instance.client;
  final _matchService = MatchService();

  /// Busca todos os jogos cadastrados
  /// 
  /// Retorna uma lista de todos os jogos cadastrados por qualquer usuário,
  /// ordenados por nome.
  Future<List<Game>> getGames() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('games')
          .select()
          .order('name', ascending: true);

      final List<Game> games = (response as List)
          .map((item) => Game.fromMap(item as Map<String, dynamic>))
          .toList();

      return games;
    } catch (e) {
      throw Exception('Erro ao buscar jogos: ${e.toString()}');
    }
  }

  /// Busca apenas os jogos base (sem expansões)
  /// 
  /// Retorna uma lista de todos os jogos que não são expansões,
  /// ou seja, jogos onde parent_game_id é null.
  Future<List<Game>> getBaseGames() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('games')
          .select()
          .isFilter('parent_game_id', null)
          .order('name', ascending: true);

      final List<Game> games = (response as List)
          .map((item) => Game.fromMap(item as Map<String, dynamic>))
          .toList();

      return games;
    } catch (e) {
      throw Exception('Erro ao buscar jogos base: ${e.toString()}');
    }
  }

  /// Busca as expansões de um jogo específico
  /// 
  /// Retorna uma lista de todos os jogos que são expansões do jogo
  /// identificado por gameId.
  Future<List<Game>> getExpansions(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('games')
          .select()
          .eq('parent_game_id', gameId)
          .order('name', ascending: true);

      final List<Game> games = (response as List)
          .map((item) => Game.fromMap(item as Map<String, dynamic>))
          .toList();

      return games;
    } catch (e) {
      throw Exception('Erro ao buscar expansões: ${e.toString()}');
    }
  }

  /// Busca um jogo específico pelo ID
  /// 
  /// Retorna o jogo se encontrado, ou null se não existir.
  /// Qualquer usuário autenticado pode buscar qualquer jogo.
  Future<Game?> getGame(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('games')
          .select()
          .eq('id', id)
          .single();

      return Game.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      // Se não encontrar, retorna null
      return null;
    }
  }

  /// Adiciona um novo jogo no Supabase
  /// 
  /// Cria um novo registro de jogo. O ID será gerado automaticamente
  /// pelo Supabase se não fornecido.
  Future<void> addGame(Game game, {Map<String, dynamic>? scoringConfig}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Valida o nome
      if (game.name.trim().isEmpty) {
        throw Exception('Nome do jogo não pode estar vazio');
      }

      // Prepara os dados para inserção
      final Map<String, dynamic> data = {
        'user_id': user.id,
        'name': game.name.trim(),
        'description': game.description?.trim(),
        'min_players': game.minPlayers,
        'max_players': game.maxPlayers,
        'play_time_minutes': game.playTimeMinutes,
        'image_url': game.imageUrl,
        'parent_game_id': game.parentGameId,
        'scoring_config': scoringConfig ?? game.scoringConfig,
      };

      // Remove campos null
      data.removeWhere((key, value) => value == null);

      await _supabase.from('games').insert(data);
    } catch (e) {
      throw Exception('Erro ao adicionar jogo: ${e.toString()}');
    }
  }

  /// Atualiza um jogo existente
  /// 
  /// Atualiza os campos do jogo identificado por game.id.
  /// Apenas o dono do jogo pode atualizá-lo (garantido pelo RLS).
  Future<void> updateGame(Game game, {Map<String, dynamic>? scoringConfig}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Valida o nome
      if (game.name.trim().isEmpty) {
        throw Exception('Nome do jogo não pode estar vazio');
      }

      // Prepara os dados para atualização
      final Map<String, dynamic> data = {
        'name': game.name.trim(),
        'description': game.description?.trim(),
        'min_players': game.minPlayers,
        'max_players': game.maxPlayers,
        'play_time_minutes': game.playTimeMinutes,
        'image_url': game.imageUrl,
        'parent_game_id': game.parentGameId,
      };

      // Remove campos null
      data.removeWhere((key, value) => value == null);
      if (scoringConfig != null) {
        data['scoring_config'] = scoringConfig;
      }

      await _supabase
          .from('games')
          .update(data)
          .eq('id', game.id);
    } catch (e) {
      throw Exception('Erro ao atualizar jogo: ${e.toString()}');
    }
  }

  /// Deleta um jogo pelo ID
  /// 
  /// Apenas o dono do jogo pode deletá-lo (garantido pelo RLS).
  /// Se o jogo tiver expansões, elas serão deletadas em cascata.
  /// Também deleta as imagens relacionadas do storage.
  Future<void> deleteGame(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca o jogo para obter a URL da imagem
      final game = await getGame(id);
      if (game != null && game.imageUrl != null && game.imageUrl!.isNotEmpty) {
        try {
          // Extrai o caminho do arquivo da URL
          final imagePath = _extractPathFromUrl(game.imageUrl!);
          if (imagePath != null) {
            // Deleta a imagem do storage
            await _supabase.storage
                .from('game-images')
                .remove([imagePath]);
          }
        } catch (e) {
          // Ignora erro ao deletar imagem, continua com a deleção do jogo
        }
      }

      // Deleta o jogo do banco de dados
      await _supabase.from('games').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar jogo: ${e.toString()}');
    }
  }

  /// Faz upload de uma imagem para o jogo
  /// 
  /// Parâmetros:
  /// - gameId: ID do jogo
  /// - file: Arquivo de imagem a ser enviado
  /// 
  /// Retorna a URL pública da imagem ou o caminho para reconstrução.
  /// 
  /// Estrutura do caminho: "{user_id}/games/{game_id}/{uuid}.jpg"
  Future<String> uploadGameImage(String gameId, File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Valida o tamanho do arquivo (máximo 5MB)
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        throw Exception('Imagem muito grande. Tamanho máximo: 5MB');
      }

      // Gera um nome único para o arquivo
      const uuid = Uuid();
      final fileName = '${uuid.v4()}.jpg';
      
      // Cria o caminho no formato: {user_id}/games/{game_id}/{uuid}.jpg
      final filePath = '${user.id}/games/$gameId/$fileName';

      // Faz upload do arquivo para o Supabase Storage
      await _supabase.storage
          .from('game-images')
          .upload(filePath, file, fileOptions: const FileOptions(
            upsert: false, // Não sobrescreve se já existir
            contentType: 'image/jpeg',
          ));

      // Obtém a URL pública do arquivo
      // Se o bucket for privado, você precisará usar createSignedUrl
      // ou tornar o bucket público apenas para leitura
      final imageUrl = _supabase.storage
          .from('game-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: ${e.toString()}');
    }
  }

  /// Extrai o caminho do arquivo de uma URL do Supabase Storage
  /// 
  /// Útil para deletar imagens quando necessário.
  /// 
  /// A URL pode ter dois formatos:
  /// 1. Público: https://{project}.supabase.co/storage/v1/object/public/game-images/{path}
  /// 2. Assinado: https://{project}.supabase.co/storage/v1/object/sign/game-images/{path}?token=...
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Procura pelo índice de 'game-images' e pega o restante
      final gameImagesIndex = pathSegments.indexOf('game-images');
      if (gameImagesIndex != -1 && gameImagesIndex < pathSegments.length - 1) {
        return pathSegments.sublist(gameImagesIndex + 1).join('/');
      }
      
      // Se não encontrar, tenta extrair do path direto
      // Remove query parameters se houver
      final cleanPath = uri.path;
      if (cleanPath.contains('game-images/')) {
        final parts = cleanPath.split('game-images/');
        if (parts.length > 1) {
          return parts[1].split('?').first; // Remove query params
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Busca sugestões de jogos baseadas na frequência de partidas
  /// 
  /// Retorna os top 3 jogos mais jogados pelo usuário,
  /// ordenados por número de partidas (mais frequentes primeiro).
  Future<List<Game>> getGameSuggestions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca todas as partidas do usuário
      final matches = await _matchService.getRecentMatches(limit: 1000);

      // Conta a frequência de cada jogo
      final Map<String, int> gameFrequency = {};
      for (var match in matches) {
        gameFrequency[match.gameName] = 
            (gameFrequency[match.gameName] ?? 0) + 1;
      }

      // Ordena por frequência (mais jogados primeiro)
      final sortedGames = gameFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Busca os top 3 jogos no banco de dados
      final List<Game> suggestions = [];
      final allGames = await getGames();
      
      for (var entry in sortedGames.take(3)) {
        final game = allGames.firstWhere(
          (g) => g.name.toLowerCase() == entry.key.toLowerCase(),
          orElse: () => Game(
            id: '',
            userId: user.id,
            name: entry.key,
            createdAt: DateTime.now(),
          ),
        );
        
        if (game.id.isNotEmpty) {
          suggestions.add(game);
        }
      }

      return suggestions;
    } catch (e) {
      // Em caso de erro, retorna lista vazia
      return [];
    }
  }
}

