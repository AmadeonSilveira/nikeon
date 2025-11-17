import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/game_card.dart';
import '../services/game_service.dart';
import '../models/game.dart';
import 'edit_game_screen.dart';
import 'game_details_screen.dart';

/// Tela de "Meus Jogos"
/// 
/// Exibe a lista de jogos cadastrados pelo usuário,
/// permitindo visualizar, adicionar, editar e deletar jogos.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _gameService = GameService();
  List<Game> _games = [];
  Map<String, String> _parentGameNames = {}; // Cache de nomes de jogos base
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  /// Carrega a lista de jogos do usuário
  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final games = await _gameService.getGames();
      
      // Carrega os nomes dos jogos base para expansões
      final Map<String, String> parentNames = {};
      for (var game in games) {
        if (game.isExpansion && game.parentGameId != null) {
          if (!parentNames.containsKey(game.parentGameId)) {
            final parentGame = await _gameService.getGame(game.parentGameId!);
            if (parentGame != null) {
              parentNames[game.parentGameId!] = parentGame.name;
            }
          }
        }
      }

      setState(() {
        _games = games;
        _parentGameNames = parentNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar jogos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega para a tela de adicionar/editar jogo
  Future<void> _navigateToEditGame({Game? game}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGameScreen(game: game),
      ),
    );

    // Se um jogo foi salvo, recarrega a lista
    if (result == true && mounted) {
      await _loadGames();
    }
  }

  /// Navega para os detalhes do jogo
  Future<void> _navigateToGameDetails(Game game) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailsScreen(game: game),
      ),
    );

    // Se o jogo foi deletado ou editado, recarrega a lista
    if (result == true && mounted) {
      await _loadGames();
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
              // Header
              _buildHeader(),
              
              // Conteúdo
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: NeonTheme.teal,
                        ),
                      )
                    : _games.isEmpty
                        ? _buildEmptyState()
                        : _buildGamesList(),
              ),
            ],
          ),
        ),
      ),
      // Botão flutuante para adicionar jogo
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditGame(),
        backgroundColor: NeonTheme.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Constrói o header da tela
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Botão de voltar
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
          const SizedBox(width: 16),
          // Título
          const Expanded(
            child: Text(
              'Meus Jogos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NeonTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 80,
              color: NeonTheme.teal.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum jogo cadastrado ainda.',
              style: TextStyle(
                fontSize: 18,
                color: NeonTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no botão + para adicionar seu primeiro jogo!',
              style: TextStyle(
                fontSize: 14,
                color: NeonTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a lista de jogos
  Widget _buildGamesList() {
    return RefreshIndicator(
      onRefresh: _loadGames,
      color: NeonTheme.teal,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return GameCard(
            game: game,
            parentGameName: game.isExpansion
                ? _parentGameNames[game.parentGameId]
                : null,
            onTap: () => _navigateToGameDetails(game),
          );
        },
      ),
    );
  }
}

