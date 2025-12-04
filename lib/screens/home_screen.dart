import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_stat_card.dart';
import '../components/match_tile.dart';
import '../widgets/neon_bottom_nav_bar.dart';
import '../widgets/neon_fab.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/game_service.dart';
import '../services/ranking_service.dart';
import '../models/match.dart';
import 'register_match_screen.dart';
import 'games_screen.dart';
import 'welcome_screen.dart';
import 'ranking_screen.dart';

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
  final _rankingService = RankingService();
  
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
  int _currentIndex = -1; // -1=Home, 0=Games, 1=Ranking
  List<Match> _allMatches = [];
  bool _isLoadingAdvancedStats = true;
  String? _mostPlayedGame;
  int _mostPlayedCount = 0;
  String? _mostWinsGame;
  int _mostWinsCount = 0;
  String? _lastGamePlayed;
  bool _streakIsWin = true;
  int _streakCount = 0;
  String? _winRateText;
  int _totalMinutesPlayed = 0;
  String? _rankingPositionText;

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
      _loadAdvancedStats(),
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

  Future<void> _loadAdvancedStats() async {
    setState(() {
      _isLoadingAdvancedStats = true;
    });
    try {
      final matches = await _matchService.getRecentMatches(limit: 200);
      final games = await _gameService.getGames();
      final gameMap = {
        for (var game in games) game.name: game,
      };

      setState(() {
        _allMatches = matches;
      });

      // Busca participantes vencedores para todas as partidas
      final matchIds = matches.map((m) => m.id).toList();
      final user = _authService.getCurrentUser();
      
      Set<String> winningMatchIds = {};
      Set<String> matchesWithParticipants = {};
      
      if (matchIds.isNotEmpty && user != null) {
        try {
          final supabase = Supabase.instance.client;
          
          // Busca todos os participantes do usuário (vencedores e não vencedores)
          // Usa uma abordagem com OR para filtrar por múltiplos match_ids
          String orFilter = matchIds.map((id) => 'match_id.eq.$id').join(',');
          
          final allParticipantsResponse = await supabase
              .from('match_participants')
              .select('match_id, is_winner')
              .or(orFilter)
              .eq('user_id', user.id);
          
          final List<dynamic> allParticipants = allParticipantsResponse as List;
          
          for (var participant in allParticipants) {
            final pMap = participant as Map<String, dynamic>;
            final matchId = pMap['match_id'] as String;
            final isWinner = pMap['is_winner'] as bool? ?? false;
            
            matchesWithParticipants.add(matchId);
            if (isWinner) {
              winningMatchIds.add(matchId);
            }
          }
        } catch (e) {
          // Se houver erro ao buscar participantes, usa o campo result como fallback
          print('Erro ao buscar participantes: $e');
        }
      }

      final playCounts = <String, int>{};
      final winCounts = <String, int>{};
      int totalMinutes = 0;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      int totalLast7 = 0;
      int winsLast7 = 0;

      for (var match in matches) {
        final name = match.gameName;
        playCounts[name] = (playCounts[name] ?? 0) + 1;
        
        // Verifica se o usuário venceu baseado nos participantes
        // Se a partida não tiver participantes, usa o campo result como fallback
        final isWin = matchesWithParticipants.contains(match.id)
            ? winningMatchIds.contains(match.id)
            : match.isWin;
        
        if (isWin) {
          winCounts[name] = (winCounts[name] ?? 0) + 1;
        }
        
        final game = gameMap[name];
        if (game?.playTimeMinutes != null) {
          totalMinutes += game!.playTimeMinutes!;
        }
        if (match.playedAt.isAfter(weekAgo)) {
          totalLast7++;
          if (isWin) winsLast7++;
        }
      }

      final mostPlayedEntry = playCounts.entries.fold<MapEntry<String, int>?>(
        null,
        (current, next) {
          if (current == null || next.value > current.value) return next;
          return current;
        },
      );
      final mostWinsEntry = winCounts.entries.fold<MapEntry<String, int>?>(
        null,
        (current, next) {
          if (current == null || next.value > current.value) return next;
          return current;
        },
      );

      String streakGameName = '';
      bool streakIsWin = true;
      int streakCount = 0;
      if (matches.isNotEmpty) {
        // Determina o resultado da primeira partida baseado em participantes
        final firstMatch = matches.first;
        final firstMatchIsWin = matchesWithParticipants.contains(firstMatch.id)
            ? winningMatchIds.contains(firstMatch.id)
            : firstMatch.isWin;
        streakIsWin = firstMatchIsWin;
        streakGameName = firstMatch.gameName;
        
        for (var match in matches) {
          // Verifica se o usuário venceu baseado nos participantes
          final matchIsWin = matchesWithParticipants.contains(match.id)
              ? winningMatchIds.contains(match.id)
              : match.isWin;
          
          if ((matchIsWin && streakIsWin) || (!matchIsWin && !streakIsWin)) {
            streakCount++;
          } else {
            break;
          }
        }
      }

      final String rankingPositionText;
      if (user != null) {
        final globalRanking = await _rankingService.getGlobalRanking(limit: 1000);
        final position = globalRanking.indexWhere((entry) => entry.userId == user.id);
        if (position != -1) {
          rankingPositionText = 'Sua posição no ranking: #${position + 1}';
        } else {
          rankingPositionText = 'Você ainda não aparece no ranking global';
        }
      } else {
        rankingPositionText = 'Você ainda não aparece no ranking global';
      }

      setState(() {
        _mostPlayedGame = mostPlayedEntry?.key;
        _mostPlayedCount = mostPlayedEntry?.value ?? 0;
        _mostWinsGame = mostWinsEntry?.key;
        _mostWinsCount = mostWinsEntry?.value ?? 0;
        _lastGamePlayed = matches.isNotEmpty ? matches.first.gameName : null;
        _streakIsWin = streakIsWin;
        _streakCount = streakCount;
        _winRateText = totalLast7 > 0
            ? '${((winsLast7 / totalLast7) * 100).toStringAsFixed(0)}%'
            : null;
        _totalMinutesPlayed = totalMinutes;
        if (totalLast7 == 0) {
          _winRateText = 'Nenhuma partida na última semana';
        }
        _rankingPositionText = rankingPositionText;
        _isLoadingAdvancedStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAdvancedStats = false;
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
      _loadAdvancedStats(),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: NeonFAB(onPressed: _navigateToRegisterMatch),
      bottomNavigationBar: NeonBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _handleBottomNavTap,
      ),
    );
  }

  void _handleBottomNavTap(int navIndex) {
    setState(() => _currentIndex = navIndex);
    if (navIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GamesScreen()),
      );
    } else if (navIndex == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RankingScreen()),
      );
    }
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
              // Botão Ranking
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
                          builder: (context) => const RankingScreen(),
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
                        Icons.leaderboard,
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
        const SizedBox(height: 24),
        _buildAdvancedStatsSection(),
      ],
    );
  }

  Widget _buildAdvancedStatsSection() {
    if (_isLoadingAdvancedStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: CircularProgressIndicator(color: NeonTheme.teal),
        ),
      );
    }

    final cards = [
      _buildAdvancedCard(
        title: 'Jogo mais jogado',
        value: _mostPlayedGame != null
            ? '$_mostPlayedGame · $_mostPlayedCount partidas'
            : 'Nenhuma partida',
        icon: Icons.local_fire_department,
        color: NeonTheme.green,
      ),
      _buildAdvancedCard(
        title: 'Mais vitórias em',
        value: _mostWinsGame != null
            ? '$_mostWinsGame · $_mostWinsCount vitórias'
            : 'Nenhuma vitória registrada',
        icon: Icons.emoji_events,
        color: NeonTheme.green,
      ),
      _buildAdvancedCard(
        title: 'Último jogo',
        value: _lastGamePlayed ?? 'Nenhuma partida',
        icon: Icons.history,
        color: NeonTheme.teal,
      ),
      _buildAdvancedCard(
        title: 'Streak atual',
        value: _streakCount > 0
            ? '$_streakCount ${_streakIsWin ? 'vitórias' : 'derrotas'}'
            : 'Sem partidas recentes',
        icon: _streakIsWin ? Icons.trending_up : Icons.trending_down,
        color: _streakIsWin ? NeonTheme.green : NeonTheme.pink,
      ),
      _buildAdvancedCard(
        title: 'Winrate 7 dias',
        value: _winRateText ?? 'Nenhuma partida na última semana',
        icon: Icons.calendar_today,
        color: NeonTheme.magenta,
      ),
      _buildAdvancedCard(
        title: 'Tempo total jogado',
        value: _formatDuration(_totalMinutesPlayed),
        icon: Icons.timer,
        color: NeonTheme.teal,
      ),
      _buildAdvancedCard(
        title: 'Ranking global',
        value: _rankingPositionText ?? 'Você ainda não aparece no ranking global',
        icon: Icons.leaderboard,
        color: NeonTheme.green,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas avançadas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: NeonTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildAdvancedCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return NeonStatCard(
      title: title,
      value: value,
      accentColor: color,
      icon: icon,
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0 min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours > 0) {
      return '$hours h ${remaining} m';
    }
    return '$remaining min';
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
