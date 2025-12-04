import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../services/ranking_service.dart';
import '../models/ranking_entry.dart';
import '../components/ranking_tile.dart';
import '../widgets/neon_bottom_nav_bar.dart';
import '../widgets/neon_fab.dart';
import 'home_screen.dart';
import 'register_match_screen.dart';
import 'games_screen.dart';

/// Tela de Ranking Global
/// 
/// Exibe o ranking global de todos os jogadores do Nikeon,
/// ordenado por pontuação (score). Mantém o estilo visual neon gamer premium.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _rankingService = RankingService();
  
  List<RankingEntry> _ranking = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  /// Carrega o ranking global
  Future<void> _loadRanking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ranking = await _rankingService.getGlobalRanking();
      setState(() {
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header com botão de voltar
                _buildHeader(),
                const SizedBox(height: 24),
                // Título e subtítulo
                _buildTitleSection(),
                const SizedBox(height: 24),
                // Conteúdo (lista de ranking)
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: NeonFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterMatchScreen()),
          );
        },
      ),
      bottomNavigationBar: NeonBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GamesScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
      ),
    );
  }

  /// Constrói o header com botão de voltar
  Widget _buildHeader() {
    return Row(
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
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                  Icons.arrow_back,
                  color: NeonTheme.teal,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói a seção de título e subtítulo
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ranking Global',
          style: NeonTheme.titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Top jogadores do Nikeon',
          style: NeonTheme.subtitleStyle,
        ),
      ],
    );
  }

  /// Constrói o conteúdo principal (loading, erro ou lista)
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: NeonTheme.teal,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NeonTheme.pink.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.pink.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: NeonTheme.pink,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar ranking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: NeonTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRanking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.teal.withOpacity(0.2),
                  foregroundColor: NeonTheme.teal,
                  side: BorderSide(
                    color: NeonTheme.teal.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ranking.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NeonTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                color: NeonTheme.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum jogador no ranking ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NeonTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _ranking.length,
      itemBuilder: (context, index) {
        return RankingTile(entry: _ranking[index]);
      },
    );
  }
}

