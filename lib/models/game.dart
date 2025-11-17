/// Modelo de dados para um jogo
/// 
/// Representa um jogo cadastrado pelo usuário, podendo ser
/// um jogo base ou uma expansão de outro jogo.
class Game {
  /// ID único do jogo
  final String id;
  
  /// ID do usuário que cadastrou o jogo
  final String userId;
  
  /// Nome do jogo
  final String name;
  
  /// Descrição do jogo (opcional)
  final String? description;
  
  /// Número mínimo de jogadores (opcional)
  final int? minPlayers;
  
  /// Número máximo de jogadores (opcional)
  final int? maxPlayers;
  
  /// Tempo médio de jogo em minutos (opcional)
  final int? playTimeMinutes;
  
  /// URL da imagem do jogo (opcional)
  final String? imageUrl;
  
  /// ID do jogo base, se este for uma expansão (opcional)
  final String? parentGameId;
  
  /// Data/hora de criação do registro
  final DateTime createdAt;

  const Game({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.minPlayers,
    this.maxPlayers,
    this.playTimeMinutes,
    this.imageUrl,
    this.parentGameId,
    required this.createdAt,
  });

  /// Cria uma instância de Game a partir de um Map (do Supabase)
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      minPlayers: map['min_players'] != null 
          ? (map['min_players'] as num).toInt() 
          : null,
      maxPlayers: map['max_players'] != null 
          ? (map['max_players'] as num).toInt() 
          : null,
      playTimeMinutes: map['play_time_minutes'] != null 
          ? (map['play_time_minutes'] as num).toInt() 
          : null,
      imageUrl: map['image_url'] as String?,
      parentGameId: map['parent_game_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converte a instância para um Map (para inserção/atualização no Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'play_time_minutes': playTimeMinutes,
      'image_url': imageUrl,
      'parent_game_id': parentGameId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Cria uma cópia do Game com campos atualizados
  Game copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    int? playTimeMinutes,
    String? imageUrl,
    String? parentGameId,
    DateTime? createdAt,
  }) {
    return Game(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      parentGameId: parentGameId ?? this.parentGameId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Retorna true se este jogo é uma expansão
  bool get isExpansion => parentGameId != null;

  /// Retorna a string de jogadores formatada (ex: "2-4 jogadores")
  String get playersString {
    if (minPlayers != null && maxPlayers != null) {
      if (minPlayers == maxPlayers) {
        return '$minPlayers jogador${minPlayers! > 1 ? 'es' : ''}';
      }
      return '$minPlayers-$maxPlayers jogadores';
    } else if (minPlayers != null) {
      return '$minPlayers+ jogadores';
    } else if (maxPlayers != null) {
      return 'Até $maxPlayers jogadores';
    }
    return 'Jogadores não especificado';
  }

  /// Retorna o tempo de jogo formatado (ex: "60 min")
  String get playTimeString {
    if (playTimeMinutes == null) return 'Tempo não especificado';
    if (playTimeMinutes! < 60) {
      return '${playTimeMinutes} min';
    }
    final hours = playTimeMinutes! ~/ 60;
    final minutes = playTimeMinutes! % 60;
    if (minutes == 0) {
      return '${hours} ${hours > 1 ? 'horas' : 'hora'}';
    }
    return '${hours}h ${minutes}min';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

