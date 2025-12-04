import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';

/// Serviço para gerenciar jogadores no Supabase
/// 
/// Centraliza a lógica de busca de jogadores registrados na plataforma.
class PlayerService {
  // Cliente Supabase global
  final _supabase = Supabase.instance.client;

  /// Busca todos os jogadores registrados na plataforma
  /// 
  /// Retorna uma lista de todos os perfis de usuários (jogadores),
  /// ordenados por nome.
  Future<List<Player>> getAllPlayers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('profiles')
          .select('id, name, email')
          .order('name', ascending: true);

      final List<Player> players = (response as List)
          .map((item) => Player.fromMap(item as Map<String, dynamic>))
          .toList();

      return players;
    } catch (e) {
      throw Exception('Erro ao buscar jogadores: ${e.toString()}');
    }
  }

  /// Busca jogadores com sugestão baseada em frequência de participação
  /// 
  /// Retorna uma lista de jogadores ordenados por frequência de participação
  /// nas partidas do usuário atual, priorizando os mais frequentes.
  /// 
  /// Os jogadores são ordenados por:
  /// 1. Frequência de participação (mais frequentes primeiro)
  /// 2. Nome (ordem alfabética)
  Future<List<Player>> getPlayersWithFrequency() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca participantes das partidas do usuário atual
      final participantsResponse = await _supabase
          .from('match_participants')
          .select('user_id, match_id')
          .not('user_id', 'is', null);

      // Busca as partidas do usuário
      final matchesResponse = await _supabase
          .from('matches')
          .select('id')
          .eq('user_id', user.id);

      final List<dynamic> matches = matchesResponse as List;
      final List<String> matchIds = matches.map((m) => m['id'] as String).toList();

      // Filtra participantes que pertencem às partidas do usuário
      final List<dynamic> participants = participantsResponse as List;
      final Map<String, int> frequencyMap = {};
      
      for (var participant in participants) {
        final userId = participant['user_id'] as String?;
        final matchId = participant['match_id'] as String;
        
        if (userId != null && matchIds.contains(matchId)) {
          frequencyMap[userId] = (frequencyMap[userId] ?? 0) + 1;
        }
      }

      // Busca todos os perfis
      final allPlayers = await getAllPlayers();

      // Adiciona frequência aos jogadores e ordena
      final List<Player> playersWithFrequency = allPlayers.map((player) {
        return Player(
          id: player.id,
          name: player.name,
          email: player.email,
          participationFrequency: frequencyMap[player.id] ?? 0,
        );
      }).toList();

      // Ordena por frequência (decrescente) e depois por nome
      playersWithFrequency.sort((a, b) {
        final freqA = a.participationFrequency ?? 0;
        final freqB = b.participationFrequency ?? 0;
        
        if (freqA != freqB) {
          return freqB.compareTo(freqA); // Mais frequentes primeiro
        }
        return a.name.compareTo(b.name); // Ordem alfabética
      });

      return playersWithFrequency;
    } catch (e) {
      // Em caso de erro, retorna lista vazia ou todos os jogadores sem frequência
      try {
        return await getAllPlayers();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Busca jogadores filtrados por nome
  /// 
  /// Retorna uma lista de jogadores cujo nome contém o termo de busca.
  /// A busca é case-insensitive.
  Future<List<Player>> searchPlayers(String searchTerm) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      if (searchTerm.trim().isEmpty) {
        return await getAllPlayers();
      }

      final response = await _supabase
          .from('profiles')
          .select('id, name, email')
          .ilike('name', '%${searchTerm.trim()}%')
          .order('name', ascending: true);

      final List<Player> players = (response as List)
          .map((item) => Player.fromMap(item as Map<String, dynamic>))
          .toList();

      return players;
    } catch (e) {
      throw Exception('Erro ao buscar jogadores: ${e.toString()}');
    }
  }
}

