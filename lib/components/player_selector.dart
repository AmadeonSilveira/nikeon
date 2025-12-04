import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../models/player.dart';
import '../services/player_service.dart';
import 'neon_text_field.dart';

/// Componente de seleção de jogadores com busca
/// 
/// Exibe um dropdown com busca filtrada por jogadores registrados
/// e opção para adicionar convidados.
class PlayerSelector extends StatefulWidget {
  /// Lista de IDs de jogadores já selecionados (para evitar duplicatas)
  final List<String> selectedPlayerIds;
  
  /// Callback quando um jogador é selecionado
  final Function(Player) onPlayerSelected;
  
  /// Callback quando a opção "Adicionar convidado" é selecionada
  /// Recebe a quantidade de convidados a adicionar
  final Function(int) onAddGuest;

  const PlayerSelector({
    super.key,
    required this.selectedPlayerIds,
    required this.onPlayerSelected,
    required this.onAddGuest,
  });

  @override
  State<PlayerSelector> createState() => _PlayerSelectorState();
}

class _PlayerSelectorState extends State<PlayerSelector> {
  final _playerService = PlayerService();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  List<Player> _allPlayers = [];
  List<Player> _filteredPlayers = [];
  bool _isLoading = true;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(_filterPlayers);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isOpen) {
        setState(() {
          _isOpen = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Carrega os jogadores com frequência de participação
  Future<void> _loadPlayers() async {
    try {
      final players = await _playerService.getPlayersWithFrequency();
      setState(() {
        _allPlayers = players;
        _filteredPlayers = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Filtra os jogadores baseado no termo de busca
  void _filterPlayers() {
    final searchTerm = _searchController.text.toLowerCase().trim();
    
    if (searchTerm.isEmpty) {
      setState(() {
        _filteredPlayers = _allPlayers;
      });
      return;
    }

    setState(() {
      _filteredPlayers = _allPlayers
          .where((player) =>
              player.name.toLowerCase().contains(searchTerm) ||
              player.email.toLowerCase().contains(searchTerm))
          .toList();
    });
  }

  /// Filtra jogadores que ainda não foram selecionados
  List<Player> get _availablePlayers {
    return _filteredPlayers
        .where((player) => !widget.selectedPlayerIds.contains(player.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de busca
        NeonTextField(
          label: 'Buscar jogador',
          icon: Icons.search,
          controller: _searchController,
          focusNode: _focusNode,
        ),
        
        // Lista de jogadores (quando aberto)
        if (_isOpen) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.teal.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: NeonTheme.teal),
                    ),
                  )
                : _availablePlayers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _searchController.text.trim().isEmpty
                                  ? 'Nenhum jogador disponível'
                                  : 'Nenhum jogador encontrado',
                              style: const TextStyle(
                                color: NeonTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botão para adicionar convidado
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _isOpen = false;
                                  _searchController.clear();
                                  _focusNode.unfocus();
                                });
                                final quantity = await _showAddGuestDialog(context);
                                if (quantity != null && quantity > 0) {
                                  widget.onAddGuest(quantity);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: NeonTheme.magenta.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: NeonTheme.magenta.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      color: NeonTheme.magenta,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Adicionar convidado',
                                      style: TextStyle(
                                        color: NeonTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _availablePlayers.length + 1, // +1 para opção de convidado
                        itemBuilder: (context, index) {
                          // Último item é a opção de adicionar convidado
                          if (index == _availablePlayers.length) {
                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _isOpen = false;
                                  _searchController.clear();
                                  _focusNode.unfocus();
                                });
                                final quantity = await _showAddGuestDialog(context);
                                if (quantity != null && quantity > 0) {
                                  widget.onAddGuest(quantity);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border(
                                    top: BorderSide(
                                      color: NeonTheme.magenta.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      color: NeonTheme.magenta,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Adicionar convidado',
                                      style: TextStyle(
                                        color: NeonTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final player = _availablePlayers[index];
                          final isFrequent = (player.participationFrequency ?? 0) > 0;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _isOpen = false;
                                _searchController.clear();
                                _focusNode.unfocus();
                              });
                              widget.onPlayerSelected(player);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: NeonTheme.teal.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              player.name,
                                              style: const TextStyle(
                                                color: NeonTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (isFrequent) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: NeonTheme.green.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Frequente',
                                                  style: TextStyle(
                                                    color: NeonTheme.green,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          player.email,
                                          style: const TextStyle(
                                            color: NeonTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: NeonTheme.teal,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }

  /// Mostra um diálogo para o usuário informar a quantidade de convidados
  Future<int?> _showAddGuestDialog(BuildContext context) async {
    final quantityController = TextEditingController(text: '1');
    
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text(
          'Adicionar Convidados',
          style: TextStyle(color: NeonTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quantos convidados deseja adicionar?',
              style: TextStyle(color: NeonTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: NeonTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Quantidade',
                labelStyle: const TextStyle(color: NeonTheme.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: NeonTheme.teal.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: NeonTheme.teal),
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text.trim());
              if (quantity != null && quantity > 0) {
                Navigator.pop(context, quantity);
              }
            },
            child: const Text(
              'Adicionar',
              style: TextStyle(color: NeonTheme.teal),
            ),
          ),
        ],
      ),
    );
  }
}

