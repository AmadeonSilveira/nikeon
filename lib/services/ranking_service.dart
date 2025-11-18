import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_entry.dart';

/// Serviço responsável por consultar os rankings no Supabase
///
/// Este serviço abstrai o acesso às tabelas:
/// - leaderboard (ranking global)
/// - leaderboard_by_game (ranking por jogo)
class RankingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Busca o ranking global completo (ordenado por score desc)
  ///
  /// Retorna uma lista de [RankingEntry] com a posição já calculada.
  Future<List<RankingEntry>> getGlobalRanking({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select('user_id, score, wins, losses, matches, profiles(name)')
          .order('score', ascending: false)
          .limit(limit);

      final data = response as List<dynamic>;
      return _mapRankingEntries(data);
    } catch (e) {
      throw Exception('Erro ao carregar ranking global: ${e.toString()}');
    }
  }

  /// Busca o ranking específico de um jogo (ordenado por score desc)
  Future<List<RankingEntry>> getGameRanking(
    String gameId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('leaderboard_by_game')
          .select('user_id, game_id, score, wins, losses, matches, profiles(name)')
          .eq('game_id', gameId)
          .order('score', ascending: false)
          .limit(limit);

      final data = response as List<dynamic>;
      return _mapRankingEntries(data);
    } catch (e) {
      throw Exception('Erro ao carregar ranking do jogo: ${e.toString()}');
    }
  }

  /// Retorna o registro do usuário logado no ranking global
  Future<RankingEntry?> getUserGlobalStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final response = await _supabase
          .from('leaderboard')
          .select('user_id, score, wins, losses, matches, profiles(name)')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return RankingEntry.fromMap(response as Map<String, dynamic>, position: 0);
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas do usuário: ${e.toString()}');
    }
  }

  /// Retorna o registro do usuário logado no ranking de um jogo específico
  Future<RankingEntry?> getUserGameStats(String gameId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final response = await _supabase
          .from('leaderboard_by_game')
          .select('user_id, game_id, score, wins, losses, matches, profiles(name)')
          .eq('user_id', user.id)
          .eq('game_id', gameId)
          .maybeSingle();

      if (response == null) return null;

      return RankingEntry.fromMap(
        response as Map<String, dynamic>,
        position: 0,
      );
    } catch (e) {
      throw Exception('Erro ao carregar ranking por jogo: ${e.toString()}');
    }
  }

  /// Calcula a pontuação de acordo com a regra atual
  ///
  /// Regra inicial: cada vitória vale 3 pontos.
  int calculateScore(int wins, int losses) {
    return wins * 3;
  }

  /// Converte a resposta crua do Supabase em uma lista de [RankingEntry]
  List<RankingEntry> _mapRankingEntries(List<dynamic> data) {
    final rankingList = <RankingEntry>[];

    for (int index = 0; index < data.length; index++) {
      final item = data[index] as Map<String, dynamic>;
      rankingList.add(
        RankingEntry.fromMap(
          item,
          position: index + 1,
        ),
      );
    }

    return rankingList;
  }
}




