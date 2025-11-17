/// Modelo de dados para uma partida
/// 
/// Representa uma partida jogada pelo usuário, com informações
/// sobre o jogo, resultado e data.
class Match {
  /// ID único da partida
  final String id;
  
  /// ID do usuário que jogou a partida
  final String userId;
  
  /// Nome do jogo jogado
  final String gameName;
  
  /// Resultado da partida ('win' ou 'loss')
  final String result;
  
  /// Data/hora em que a partida foi jogada
  final DateTime playedAt;
  
  /// Data/hora de criação do registro
  final DateTime createdAt;

  const Match({
    required this.id,
    required this.userId,
    required this.gameName,
    required this.result,
    required this.playedAt,
    required this.createdAt,
  });

  /// Cria uma instância de Match a partir de um Map (do Supabase)
  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      gameName: map['game_name'] as String,
      result: map['result'] as String,
      playedAt: DateTime.parse(map['played_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converte a instância para um Map (para inserção no Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'game_name': gameName,
      'result': result,
      'played_at': playedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Retorna se a partida foi uma vitória
  bool get isWin => result == 'win';

  /// Retorna se a partida foi uma derrota
  bool get isLoss => result == 'loss';

  /// Retorna o resultado formatado em português
  String get resultLabel {
    switch (result) {
      case 'win':
        return 'Vitória';
      case 'loss':
        return 'Derrota';
      default:
        return result;
    }
  }

  /// Retorna a data formatada de forma amigável
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
    }
  }
}

