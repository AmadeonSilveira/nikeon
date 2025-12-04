/// Modelo de dados para um jogador
/// 
/// Representa um jogador registrado na plataforma (da tabela profiles)
class Player {
  /// ID único do jogador (user_id)
  final String id;
  
  /// Nome do jogador
  final String name;
  
  /// Email do jogador
  final String email;
  
  /// Frequência de participação em partidas (para ordenação)
  final int? participationFrequency;

  const Player({
    required this.id,
    required this.name,
    required this.email,
    this.participationFrequency,
  });

  /// Cria uma instância de Player a partir de um Map (do Supabase)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      participationFrequency: map['participation_frequency'] != null
          ? (map['participation_frequency'] as num).toInt()
          : null,
    );
  }

  /// Converte a instância para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'participation_frequency': participationFrequency,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

