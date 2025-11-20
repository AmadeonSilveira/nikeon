/// Modelo que representa uma posição no ranking
///
/// Pode ser utilizado tanto para o ranking global quanto
/// para o ranking específico por jogo.
class RankingEntry {
  /// ID do usuário referenciado no ranking
  final String userId;

  /// Pontuação acumulada (score)
  final int score;

  /// Número de vitórias
  final int wins;

  /// Número de derrotas
  final int losses;

  /// Total de partidas consideradas
  final int matches;

  /// Posição no ranking (calculada em tempo de execução)
  final int position;

  /// ID do jogo (presente apenas no ranking por jogo)
  final String? gameId;

  /// Nome do usuário (buscado da tabela profiles)
  final String? username;

  const RankingEntry({
    required this.userId,
    required this.score,
    required this.wins,
    required this.losses,
    required this.matches,
    required this.position,
    this.gameId,
    this.username,
  });

  /// Cria uma instância a partir de um Map (retornado pelo Supabase)
  ///
  /// [position] deve ser fornecida externamente (serviço atribui)
  /// 
  /// Suporta dois formatos:
  /// 1. Formato antigo: profiles(name) - usado pelo ranking global
  /// 2. Formato novo: profile_name - usado pela view leaderboard_by_game_view
  factory RankingEntry.fromMap(
    Map<String, dynamic> map, {
    required int position,
    String? gameId,
  }) {
    // Tenta obter o nome do usuário de duas formas:
    // 1. Da view (profile_name direto)
    // 2. Do join aninhado (profiles(name))
    String? username;
    if (map.containsKey('profile_name')) {
      username = map['profile_name'] as String?;
    } else {
      final profileData = map['profiles'] as Map<String, dynamic>?;
      username = profileData != null ? profileData['name'] as String? : null;
    }

    return RankingEntry(
      userId: map['user_id'] as String,
      score: (map['score'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      matches: (map['matches'] as num?)?.toInt() ?? 0,
      position: position,
      gameId: gameId ?? map['game_id'] as String?,
      username: username,
    );
  }

  /// Converte a instância em Map (útil para testes ou cache)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'score': score,
      'wins': wins,
      'losses': losses,
      'matches': matches,
      'position': position,
      'game_id': gameId,
      'username': username,
    };
  }

  /// Retorna uma cópia com campos alterados
  RankingEntry copyWith({
    String? userId,
    int? score,
    int? wins,
    int? losses,
    int? matches,
    int? position,
    String? gameId,
    String? username,
  }) {
    return RankingEntry(
      userId: userId ?? this.userId,
      score: score ?? this.score,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      matches: matches ?? this.matches,
      position: position ?? this.position,
      gameId: gameId ?? this.gameId,
      username: username ?? this.username,
    );
  }
}





