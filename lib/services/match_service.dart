import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match.dart';
import '../models/match_participant.dart';

/// Serviço para gerenciar partidas no Supabase
/// 
/// Centraliza toda a lógica de CRUD de partidas, incluindo
/// busca de estatísticas e criação de novas partidas.
class MatchService {
  // Cliente Supabase global
  final _supabase = Supabase.instance.client;

  /// Busca as últimas partidas do usuário logado
  /// 
  /// Retorna uma lista das últimas partidas ordenadas por data
  /// (mais recentes primeiro). Por padrão retorna as 10 mais recentes.
  Future<List<Match>> getRecentMatches({int limit = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await _supabase
          .from('matches')
          .select()
          .eq('user_id', user.id)
          .order('played_at', ascending: false)
          .limit(limit);

      final List<Match> matches = (response as List)
          .map((item) => Match.fromMap(item as Map<String, dynamic>))
          .toList();

      return matches;
    } catch (e) {
      throw Exception('Erro ao buscar partidas: ${e.toString()}');
    }
  }

  /// Busca as estatísticas do usuário logado
  /// 
  /// Retorna um Map com:
  /// - 'total': total de partidas jogadas
  /// - 'wins': número de vitórias (baseado em participantes vencedores)
  /// - 'losses': número de derrotas
  /// 
  /// Agora considera os participantes vencedores em vez de apenas o campo result.
  Future<Map<String, int>> getStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca todas as partidas do usuário com seus IDs
      final matchesResponse = await _supabase
          .from('matches')
          .select('id, result')
          .eq('user_id', user.id);

      final List<dynamic> matches = matchesResponse as List;
      final int total = matches.length;

      if (total == 0) {
        return {
          'total': 0,
          'wins': 0,
          'losses': 0,
        };
      }

      // Busca os IDs das partidas
      final matchIds = matches.map((m) => (m as Map<String, dynamic>)['id'] as String).toList();

      // Busca participantes vencedores do usuário para essas partidas
      // Usa uma abordagem com OR para filtrar por múltiplos match_ids
      if (matchIds.isEmpty) {
        return {
          'total': 0,
          'wins': 0,
          'losses': 0,
        };
      }

      // Constrói filtro OR para múltiplos match_ids
      String orFilter = matchIds.map((id) => 'match_id.eq.$id').join(',');
      
      final participantsResponse = await _supabase
          .from('match_participants')
          .select('match_id')
          .or(orFilter)
          .eq('user_id', user.id)
          .eq('is_winner', true);

      final List<dynamic> winningParticipants = participantsResponse as List;
      final Set<String> winningMatchIds = winningParticipants
          .map((p) => (p as Map<String, dynamic>)['match_id'] as String)
          .toSet();

      // Calcula vitórias baseado nos participantes vencedores
      // Se não houver participantes vencedores, usa o campo result como fallback
      int wins = 0;
      int losses = 0;

      for (var match in matches) {
        final matchMap = match as Map<String, dynamic>;
        final matchId = matchMap['id'] as String;
        final result = matchMap['result'] as String;

        // Verifica se o usuário está entre os vencedores pelos participantes
        if (winningMatchIds.contains(matchId)) {
          wins++;
        } else {
          // Fallback: usa o campo result se não houver participantes
          // (pode acontecer em partidas antigas sem participantes)
          if (result == 'win') {
            wins++;
          } else {
            losses++;
          }
        }
      }

      return {
        'total': total,
        'wins': wins,
        'losses': losses,
      };
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: ${e.toString()}');
    }
  }

  /// Cria uma nova partida no Supabase
  /// 
  /// Parâmetros:
  /// - gameName: Nome do jogo jogado
  /// - playedAt: Data/hora em que a partida foi jogada (opcional, usa agora se não fornecido)
  /// - participants: Lista de participantes da partida (obrigatório)
  ///
  /// O resultado da partida é calculado automaticamente baseado nos participantes vencedores.
  /// Se o usuário atual estiver entre os vencedores, result = 'win', caso contrário 'loss'.
  ///
  /// Observação: O ranking global e por jogo é atualizado automaticamente
  /// por triggers configurados no banco (não é necessário chamar nada extra aqui).
  Future<void> createMatch({
    required String gameName,
    required List<MatchParticipant> participants,
    DateTime? playedAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Valida o nome do jogo
      if (gameName.trim().isEmpty) {
        throw Exception('Nome do jogo não pode estar vazio');
      }

      // Valida se há participantes
      if (participants.isEmpty) {
        throw Exception('É necessário pelo menos um participante');
      }

      // Calcula o resultado baseado nos participantes vencedores
      // Se o usuário atual estiver entre os vencedores, result = 'win'
      final userIsWinner = participants.any((p) => 
        p.userId == user.id && p.isWinner
      );
      final result = userIsWinner ? 'win' : 'loss';

      // Usa a data atual se não fornecida
      final matchDate = playedAt ?? DateTime.now();

      // Insere a partida no banco de dados
      final matchResponse = await _supabase
          .from('matches')
          .insert({
            'user_id': user.id,
            'game_name': gameName.trim(),
            'result': result,
            'played_at': matchDate.toIso8601String(),
          })
          .select()
          .single();

      final matchId = matchResponse['id'] as String;

      // Insere os participantes
      final participantsData = participants.map((participant) {
        return {
          'match_id': matchId,
          'user_id': participant.userId,
          'name': participant.name,
          'is_winner': participant.isWinner,
          'score': participant.score,
        };
      }).toList();

      await _supabase.from('match_participants').insert(participantsData);
    } catch (e) {
      throw Exception('Erro ao criar partida: ${e.toString()}');
    }
  }

  /// Deleta uma partida pelo ID
  /// 
  /// Apenas o dono da partida pode deletá-la (garantido pelo RLS).
  Future<void> deleteMatch(String matchId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      await _supabase.from('matches').delete().eq('id', matchId);
    } catch (e) {
      throw Exception('Erro ao deletar partida: ${e.toString()}');
    }
  }

  /// Atualiza uma partida existente
  /// 
  /// Apenas o dono da partida pode atualizá-la (garantido pelo RLS).
  Future<void> updateMatch({
    required String matchId,
    String? gameName,
    String? result,
    DateTime? playedAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final Map<String, dynamic> updates = {};

      if (gameName != null) {
        if (gameName.trim().isEmpty) {
          throw Exception('Nome do jogo não pode estar vazio');
        }
        updates['game_name'] = gameName.trim();
      }

      if (result != null) {
        if (result != 'win' && result != 'loss') {
          throw Exception('Resultado inválido. Use "win" ou "loss"');
        }
        updates['result'] = result;
      }

      if (playedAt != null) {
        updates['played_at'] = playedAt.toIso8601String();
      }

      if (updates.isEmpty) {
        throw Exception('Nenhuma atualização fornecida');
      }

      await _supabase
          .from('matches')
          .update(updates)
          .eq('id', matchId);
    } catch (e) {
      throw Exception('Erro ao atualizar partida: ${e.toString()}');
    }
  }
}

