/// Modelo de dados para um participante de partida
/// 
/// Representa um participante de uma partida, que pode ser:
/// - Um jogador registrado na plataforma (user_id não nulo)
/// - Um convidado (user_id nulo, name fornecido)
class MatchParticipant {
  /// ID único do participante
  final String id;
  
  /// ID da partida
  final String matchId;
  
  /// ID do usuário (null para convidados)
  final String? userId;
  
  /// Nome do participante
  final String name;
  
  /// Indica se o participante venceu a partida
  final bool isWinner;
  
  /// Pontuação obtida pelo participante (opcional)
  final int? score;
  
  /// Data/hora de criação do registro
  final DateTime createdAt;

  const MatchParticipant({
    required this.id,
    required this.matchId,
    this.userId,
    required this.name,
    this.isWinner = false,
    this.score,
    required this.createdAt,
  });

  /// Retorna true se é um convidado (não tem user_id)
  bool get isGuest => userId == null;

  /// Cria uma instância de MatchParticipant a partir de um Map (do Supabase)
  factory MatchParticipant.fromMap(Map<String, dynamic> map) {
    return MatchParticipant(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      isWinner: map['is_winner'] as bool? ?? false,
      score: map['score'] != null ? (map['score'] as num).toInt() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converte a instância para um Map (para inserção/atualização no Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'user_id': userId,
      'name': name,
      'is_winner': isWinner,
      'score': score,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Cria uma cópia do MatchParticipant com campos atualizados
  MatchParticipant copyWith({
    String? id,
    String? matchId,
    String? userId,
    String? name,
    bool? isWinner,
    int? score,
    DateTime? createdAt,
  }) {
    return MatchParticipant(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isWinner: isWinner ?? this.isWinner,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

