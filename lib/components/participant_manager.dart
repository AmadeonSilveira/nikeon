import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../models/player.dart';
import '../models/match_participant.dart';
import 'neon_text_field.dart';

/// Componente para gerenciar participantes de partida
/// 
/// Permite adicionar jogadores registrados e convidados,
/// e configurar vitória e pontuação para cada um.
class ParticipantManager extends StatefulWidget {
  /// Lista de participantes atuais
  final List<MatchParticipant> participants;
  
  /// Callback quando a lista de participantes muda
  final Function(List<MatchParticipant>) onParticipantsChanged;

  const ParticipantManager({
    super.key,
    required this.participants,
    required this.onParticipantsChanged,
  });

  @override
  State<ParticipantManager> createState() => _ParticipantManagerState();
}

class _ParticipantManagerState extends State<ParticipantManager> {
  int _guestCounter = 1;

  @override
  void initState() {
    super.initState();
    // Conta convidados existentes para continuar a numeração
    _guestCounter = widget.participants.where((p) => p.isGuest).length + 1;
  }

  @override
  void didUpdateWidget(ParticipantManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza o contador de convidados quando a lista muda
    _guestCounter = widget.participants.where((p) => p.isGuest).length + 1;
  }

  /// Retorna a lista de participantes (usa a prop diretamente)
  List<MatchParticipant> get _participants => widget.participants;


  /// Remove um participante
  void _removeParticipant(String participantId) {
    final updated = _participants.where((p) => p.id != participantId).toList();
    widget.onParticipantsChanged(updated);
  }

  /// Atualiza o nome de um convidado
  void _updateGuestName(String participantId, String newName) {
    final updated = _participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(name: newName.trim().isEmpty
            ? 'Convidado ${_participants.indexOf(p) + 1}'
            : newName.trim());
      }
      return p;
    }).toList();
    widget.onParticipantsChanged(updated);
  }

  /// Atualiza se o participante venceu
  void _updateWinner(String participantId, bool isWinner) {
    final updated = _participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(isWinner: isWinner);
      }
      return p;
    }).toList();
    widget.onParticipantsChanged(updated);
  }

  /// Atualiza a pontuação de um participante
  void _updateScore(String participantId, int? score) {
    final updated = _participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(score: score);
      }
      return p;
    }).toList();
    widget.onParticipantsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participantes',
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de participantes
        if (_participants.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.teal.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text(
                'Nenhum participante adicionado ainda',
                style: TextStyle(
                  color: NeonTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._participants.map((participant) => _buildParticipantCard(participant)),
        
        const SizedBox(height: 12),
      ],
    );
  }

  /// Constrói o card de um participante
  Widget _buildParticipantCard(MatchParticipant participant) {
    final nameController = TextEditingController(text: participant.name);
    final scoreController = TextEditingController(
      text: participant.score?.toString() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant.isGuest
              ? NeonTheme.magenta.withOpacity(0.3)
              : NeonTheme.teal.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com nome e botão de remover
          Row(
            children: [
              // Ícone de tipo
              Icon(
                participant.isGuest ? Icons.person_outline : Icons.person,
                color: participant.isGuest ? NeonTheme.magenta : NeonTheme.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Nome (editável se for convidado)
              Expanded(
                child: participant.isGuest
                    ? TextFormField(
                        controller: nameController,
                        style: const TextStyle(
                          color: NeonTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          border: InputBorder.none,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: NeonTheme.magenta.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: NeonTheme.magenta,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          _updateGuestName(participant.id, value.trim().isEmpty
                              ? 'Convidado ${_participants.indexOf(participant) + 1}'
                              : value.trim());
                        },
                      )
                    : Text(
                        participant.name,
                        style: const TextStyle(
                          color: NeonTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              // Botão de remover
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: NeonTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () => _removeParticipant(participant.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Checkbox de vitória
          Row(
            children: [
              GestureDetector(
                onTap: () => _updateWinner(participant.id, !participant.isWinner),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: participant.isWinner
                        ? NeonTheme.green.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: participant.isWinner
                          ? NeonTheme.green
                          : NeonTheme.textSecondary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: participant.isWinner
                      ? const Icon(
                          Icons.check,
                          color: NeonTheme.green,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Vencedor',
                style: TextStyle(
                  color: NeonTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Campo de pontuação
          Row(
            children: [
              const Icon(
                Icons.star,
                color: NeonTheme.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pontuação:',
                style: TextStyle(
                  color: NeonTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: NeonTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: 'Opcional',
                    hintStyle: const TextStyle(
                      color: NeonTheme.textSecondary,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: NeonTheme.teal.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: NeonTheme.teal.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: NeonTheme.teal,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                  ),
                  onChanged: (value) {
                    final score = int.tryParse(value.trim());
                    _updateScore(participant.id, score);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

