import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../services/game_service.dart';
import '../services/match_service.dart';
import '../models/game.dart';
import '../models/match.dart';
import '../components/match_tile.dart';
import 'edit_game_screen.dart';
import 'game_ranking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela de detalhes de um jogo
/// 
/// Exibe informações completas do jogo, expansões,
/// partidas recentes e ações (editar, deletar).
class GameDetailsScreen extends StatefulWidget {
  final Game game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final _gameService = GameService();
  final _matchService = MatchService();
  
  List<Game> _expansions = [];
  List<Match> _recentMatches = [];
  Game? _parentGame;
  bool _isLoadingExpansions = true;
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carrega todos os dados do jogo
  Future<void> _loadData() async {
    await Future.wait([
      _loadExpansions(),
      _loadRecentMatches(),
      _loadParentGame(),
    ]);
  }

  /// Carrega as expansões do jogo
  Future<void> _loadExpansions() async {
    try {
      final expansions = await _gameService.getExpansions(widget.game.id);
      setState(() {
        _expansions = expansions;
        _isLoadingExpansions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExpansions = false;
      });
    }
  }

  /// Carrega as partidas recentes deste jogo
  Future<void> _loadRecentMatches() async {
    try {
      final allMatches = await _matchService.getRecentMatches(limit: 50);
      final filteredMatches = allMatches
          .where((match) => match.gameName == widget.game.name)
          .take(5)
          .toList();
      setState(() {
        _recentMatches = filteredMatches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMatches = false;
      });
    }
  }

  /// Carrega o jogo base (se este for uma expansão)
  Future<void> _loadParentGame() async {
    if (widget.game.isExpansion && widget.game.parentGameId != null) {
      try {
        final parent = await _gameService.getGame(widget.game.parentGameId!);
        setState(() {
          _parentGame = parent;
        });
      } catch (e) {
        // Ignora erro
      }
    }
  }

  /// Navega para editar o jogo
  Future<void> _editGame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGameScreen(game: widget.game),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  /// Deleta o jogo
  Future<void> _deleteGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: NeonTheme.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja deletar "${widget.game.name}"?',
          style: const TextStyle(color: NeonTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Deletar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _gameService.deleteGame(widget.game.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jogo deletado com sucesso!'),
              backgroundColor: NeonTheme.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar jogo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeonTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildGameImage(),
                      const SizedBox(height: 24),
                      _buildGameInfo(),
                      const SizedBox(height: 32),
                      _buildActions(),
                      const SizedBox(height: 32),
                      if (_parentGame != null) _buildParentGameInfo(),
                      if (!widget.game.isExpansion) _buildExpansionsSection(),
                      const SizedBox(height: 32),
                      _buildRecentMatchesSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: NeonTheme.teal.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: NeonTheme.teal,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameImage() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.game.isExpansion
                ? NeonTheme.magenta.withOpacity(0.4)
                : NeonTheme.teal.withOpacity(0.4),
            width: 2,
          ),
          // Brilho sutil neon
          boxShadow: [
            BoxShadow(
              color: (widget.game.isExpansion ? NeonTheme.magenta : NeonTheme.teal)
                  .withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.game.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderIcon();
                  },
                ),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.sports_esports,
        size: 80,
        color: (widget.game.isExpansion ? NeonTheme.magenta : NeonTheme.teal)
            .withOpacity(0.6),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome do jogo
        Text(
          widget.game.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: NeonTheme.textPrimary,
          ),
        ),
        // Indicador de expansão
        if (widget.game.isExpansion && _parentGame != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.extension, size: 16, color: NeonTheme.magenta),
              const SizedBox(width: 4),
              Text(
                'Expansão de ${_parentGame!.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: NeonTheme.magenta,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        // Descrição
        if (widget.game.description != null &&
            widget.game.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            widget.game.description!,
            style: const TextStyle(
              fontSize: 16,
              color: NeonTheme.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Informações adicionais
        Row(
          children: [
            if (widget.game.minPlayers != null ||
                widget.game.maxPlayers != null) ...[
              Icon(Icons.people, size: 20, color: NeonTheme.teal),
              const SizedBox(width: 8),
              Text(
                widget.game.playersString,
                style: const TextStyle(
                  fontSize: 16,
                  color: NeonTheme.textSecondary,
                ),
              ),
            ],
            if ((widget.game.minPlayers != null ||
                    widget.game.maxPlayers != null) &&
                widget.game.playTimeMinutes != null) ...[
              const SizedBox(width: 24),
              Icon(Icons.access_time, size: 20, color: NeonTheme.teal),
              const SizedBox(width: 8),
              Text(
                widget.game.playTimeString,
                style: const TextStyle(
                  fontSize: 16,
                  color: NeonTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwner = currentUser != null && widget.game.userId == currentUser.id;

    return Column(
      children: [
        // Botão de ranking (sempre visível)
        NeonButton.primary(
          text: 'Ver Ranking deste jogo',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameRankingScreen(
                  gameId: widget.game.id,
                  gameName: widget.game.name,
                ),
              ),
            );
          },
        ),
        // Botões de edição/deleção (apenas se for o dono)
        if (isOwner) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeonButton.primary(
                  text: 'Editar',
                  onPressed: _editGame,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeonButton.secondary(
                  text: 'Deletar',
                  onPressed: _deleteGame,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildParentGameInfo() {
    if (_parentGame == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.magenta.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_esports, color: NeonTheme.magenta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jogo base',
                  style: TextStyle(
                    fontSize: 12,
                    color: NeonTheme.textSecondary,
                  ),
                ),
                Text(
                  _parentGame!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expansões',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: NeonTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingExpansions)
          const Center(
            child: CircularProgressIndicator(color: NeonTheme.teal),
          )
        else if (_expansions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Nenhuma expansão cadastrada',
                style: TextStyle(
                  color: NeonTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._expansions.map((expansion) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NeonTheme.magenta.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.extension, color: NeonTheme.magenta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expansion.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: NeonTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildRecentMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Partidas recentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: NeonTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingMatches)
          const Center(
            child: CircularProgressIndicator(color: NeonTheme.teal),
          )
        else if (_recentMatches.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Nenhuma partida registrada ainda',
                style: TextStyle(
                  color: NeonTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._recentMatches.map((match) => MatchTile(match: match)),
      ],
    );
  }
}

