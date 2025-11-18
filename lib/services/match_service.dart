import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match.dart';

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
  /// - 'wins': número de vitórias
  /// - 'losses': número de derrotas
  Future<Map<String, int>> getStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca todas as partidas do usuário
      final response = await _supabase
          .from('matches')
          .select('result')
          .eq('user_id', user.id);

      final List<dynamic> matches = response as List;

      // Calcula as estatísticas
      int total = matches.length;
      int wins = 0;
      int losses = 0;

      for (var match in matches) {
        final result = (match as Map<String, dynamic>)['result'] as String;
        if (result == 'win') {
          wins++;
        } else if (result == 'loss') {
          losses++;
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
  /// - result: Resultado da partida ('win' ou 'loss')
  /// - playedAt: Data/hora em que a partida foi jogada (opcional, usa agora se não fornecido)
  ///
  /// Observação: O ranking global e por jogo é atualizado automaticamente
  /// por triggers configurados no banco (não é necessário chamar nada extra aqui).
  Future<void> createMatch({
    required String gameName,
    required String result,
    DateTime? playedAt,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Valida o resultado
      if (result != 'win' && result != 'loss') {
        throw Exception('Resultado inválido. Use "win" ou "loss"');
      }

      // Valida o nome do jogo
      if (gameName.trim().isEmpty) {
        throw Exception('Nome do jogo não pode estar vazio');
      }

      // Usa a data atual se não fornecida
      final matchDate = playedAt ?? DateTime.now();

      // Insere a partida no banco de dados
      await _supabase.from('matches').insert({
        'user_id': user.id,
        'game_name': gameName.trim(),
        'result': result,
        'played_at': matchDate.toIso8601String(),
      });
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

