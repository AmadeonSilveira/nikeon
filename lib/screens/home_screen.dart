import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_stat_card.dart';
import '../components/match_tile.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/game_service.dart';
import '../models/match.dart';
import 'register_match_screen.dart';
import 'games_screen.dart';
import 'welcome_screen.dart';

/// Tela principal (home) do app Arkion
/// 
/// Exibe um dashboard compacto com estatísticas, últimas partidas
/// e ações principais. Mantém o mesmo estilo visual neon gamer premium.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _matchService = MatchService();
  final _gameService = GameService();
  
  String? _userName;
  bool _isLoadingProfile = true;
  bool _isLoadingStats = true;
  bool _isLoadingMatches = true;
  
  // Dados do dashboard
  Map<String, int> _stats = {
    'total': 0,
    'wins': 0,
    'losses': 0,
  };
  List<Match> _recentMatches = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Carrega todos os dados necessários para o dashboard
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadStats(),
      _loadRecentMatches(),
    ]);
  }

  /// Carrega o perfil do usuário logado
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userName = profile['name'] as String?;
          _isLoadingProfile = false;
        });
      } else {
        // Se não encontrar o perfil, usa o email do usuário
        final user = _authService.getCurrentUser();
        setState(() {
          _userName = user?.email ?? 'Usuário';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Usuário';
        _isLoadingProfile = false;
      });
    }
  }

  /// Carrega as estatísticas do usuário
  Future<void> _loadStats() async {
    try {
      final stats = await _matchService.getStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  /// Carrega as últimas partidas do usuário
  Future<void> _loadRecentMatches() async {
    try {
      final matches = await _matchService.getRecentMatches(limit: 3);
      setState(() {
        _recentMatches = matches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMatches = false;
      });
    }
  }

  /// Recarrega os dados após registrar uma nova partida
  Future<void> _refreshData() async {
    setState(() {
      _isLoadingStats = true;
      _isLoadingMatches = true;
    });
    await Future.wait([
      _loadStats(),
      _loadRecentMatches(),
    ]);
  }

  /// Faz logout do usuário
  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      
      // Navega para a tela de boas-vindas
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega para a tela de registrar partida
  Future<void> _navigateToRegisterMatch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterMatchScreen(),
      ),
    );
    
    // Se uma partida foi criada, recarrega os dados
    if (result == true && mounted) {
      await _refreshData();
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
              // Header com saudação e botão de logout
              _buildHeader(),
              
              // Conteúdo scrollável
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // Cards de estatísticas
                      _buildStatsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Seção de últimas partidas
                      _buildRecentMatchesSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Botão principal de ação
                      _buildMainActionButton(),
                      
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

  /// Constrói o header com saudação e logout
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Saudação
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá,',
                  style: TextStyle(
                    fontSize: 18,
                    color: NeonTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLoadingProfile)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: NeonTheme.teal,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Text(
                    _userName ?? 'Usuário',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NeonTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Botões de ação
          Row(
            children: [
              // Botão Meus Jogos
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GamesScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.sports_esports,
                        color: NeonTheme.teal,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botão de logout
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NeonTheme.pink.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleLogout,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: NeonTheme.pink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de estatísticas
  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: NeonTheme.teal,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid de cards de estatísticas
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            NeonStatCard(
              title: 'Partidas jogadas',
              value: '${_stats['total'] ?? 0}',
              accentColor: NeonTheme.teal,
              icon: Icons.sports_esports,
            ),
            NeonStatCard(
              title: 'Vitórias',
              value: '${_stats['wins'] ?? 0}',
              accentColor: NeonTheme.green,
              icon: Icons.emoji_events,
            ),
            NeonStatCard(
              title: 'Derrotas',
              value: '${_stats['losses'] ?? 0}',
              accentColor: NeonTheme.pink,
              icon: Icons.sentiment_dissatisfied,
            ),
            NeonStatCard(
              title: 'Taxa de vitória',
              value: _stats['total']! > 0
                  ? '${((_stats['wins']! / _stats['total']!) * 100).toStringAsFixed(0)}%'
                  : '0%',
              accentColor: NeonTheme.magenta,
              icon: Icons.leaderboard,
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói a seção de últimas partidas
  Widget _buildRecentMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtítulo da seção
        const Text(
          'Últimas partidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: NeonTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        // Lista de partidas
        if (_isLoadingMatches)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: NeonTheme.teal,
              ),
            ),
          )
        else if (_recentMatches.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'Nenhuma partida registrada ainda.\nRegistre sua primeira partida!',
                textAlign: TextAlign.center,
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

  /// Constrói o botão principal de ação
  Widget _buildMainActionButton() {
    return NeonButton.primary(
      text: 'Registrar nova partida',
      onPressed: _navigateToRegisterMatch,
      height: 56,
    );
  }
}
