import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_text_field.dart';
import '../services/match_service.dart';
import '../services/game_service.dart';
import '../models/game.dart';

/// Tela para registrar uma nova partida
/// 
/// Permite que o usuário registre uma partida jogada,
/// incluindo nome do jogo, resultado e data.
class RegisterMatchScreen extends StatefulWidget {
  const RegisterMatchScreen({super.key});

  @override
  State<RegisterMatchScreen> createState() => _RegisterMatchScreenState();
}

class _RegisterMatchScreenState extends State<RegisterMatchScreen> {
  final _matchService = MatchService();
  final _gameService = GameService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores dos campos
  final _dateController = TextEditingController();
  
  // Estado do formulário
  String? _selectedGameId;
  String _selectedResult = 'win'; // 'win' ou 'loss'
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingGames = true;
  
  // Listas de jogos
  List<Game> _games = [];
  List<Game> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Define a data padrão como hoje
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate!);
    _loadGames();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  /// Carrega a lista de jogos e sugestões
  Future<void> _loadGames() async {
    try {
      final games = await _gameService.getGames();
      final suggestions = await _gameService.getGameSuggestions();
      
      setState(() {
        _games = games;
        _suggestions = suggestions;
        _isLoadingGames = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  /// Seleciona um jogo das sugestões
  void _selectSuggestion(Game game) {
    setState(() {
      _selectedGameId = game.id;
    });
  }

  /// Formata a data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Abre o seletor de data
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: NeonTheme.teal,
              onPrimary: Colors.white,
              surface: Color(0xFF0A0A0F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  /// Salva a partida no Supabase
  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um jogo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedGame = _games.firstWhere((g) => g.id == _selectedGameId);
      await _matchService.createMatch(
        gameName: selectedGame.name,
        result: _selectedResult,
        playedAt: _selectedDate,
      );

      // Retorna true para indicar que a partida foi criada
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partida registrada com sucesso!'),
            backgroundColor: NeonTheme.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar partida: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header com botão de voltar
                _buildHeader(),
                
                // Conteúdo scrollável
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        
                        // Título
                        const Text(
                          'Registrar Partida',
                          style: NeonTheme.titleStyle,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtítulo
                        const Text(
                          'Registre uma nova partida que você jogou.',
                          style: NeonTheme.subtitleStyle,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Sugestões rápidas
                        if (_suggestions.isNotEmpty) ...[
                          const Text(
                            'Sugestões rápidas',
                            style: TextStyle(
                              fontSize: 14,
                              color: NeonTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: _suggestions.take(3).map((game) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _selectSuggestion(game),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedGameId == game.id
                                            ? NeonTheme.teal.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedGameId == game.id
                                              ? NeonTheme.teal
                                              : NeonTheme.teal.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        game.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedGameId == game.id
                                              ? NeonTheme.teal
                                              : NeonTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Campo: Seleção de jogo
                        _buildGameSelector(),
                        
                        const SizedBox(height: 20),
                        
                        // Campo: Resultado
                        _buildResultSelector(),
                        
                        const SizedBox(height: 20),
                        
                        // Campo: Data
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: NeonTextField(
                              label: 'Data da partida',
                              icon: Icons.calendar_today,
                              controller: _dateController,
                              validator: (value) {
                                if (_selectedDate == null) {
                                  return 'Por favor, selecione uma data';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Botão de salvar
                        NeonButton.primary(
                          text: _isLoading ? 'Salvando...' : 'Salvar',
                          onPressed: _isLoading ? null : _saveMatch,
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o header com botão de voltar
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: NeonTheme.teal.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.teal.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
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
      ),
    );
  }

  /// Constrói o seletor de resultado
  Widget _buildResultSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultado',
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Botão: Vitória
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedResult = 'win';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedResult == 'win'
                        ? NeonTheme.green.withOpacity(0.2)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedResult == 'win'
                          ? NeonTheme.green
                          : NeonTheme.green.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: _selectedResult == 'win'
                        ? [
                            BoxShadow(
                              color: NeonTheme.green.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: _selectedResult == 'win'
                            ? NeonTheme.green
                            : NeonTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vitória',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedResult == 'win'
                              ? NeonTheme.green
                              : NeonTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Botão: Derrota
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedResult = 'loss';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedResult == 'loss'
                        ? NeonTheme.pink.withOpacity(0.2)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedResult == 'loss'
                          ? NeonTheme.pink
                          : NeonTheme.pink.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: _selectedResult == 'loss'
                        ? [
                            BoxShadow(
                              color: NeonTheme.pink.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied,
                        color: _selectedResult == 'loss'
                            ? NeonTheme.pink
                            : NeonTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Derrota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedResult == 'loss'
                              ? NeonTheme.pink
                              : NeonTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o seletor de jogo
  Widget _buildGameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jogo',
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingGames)
          const Center(
            child: CircularProgressIndicator(color: NeonTheme.teal),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.teal.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGameId,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: NeonTheme.teal),
                dropdownColor: const Color(0xFF0A0A0F),
                style: const TextStyle(color: NeonTheme.textPrimary),
                hint: const Text('Selecione um jogo'),
                items: _games.map((game) {
                  return DropdownMenuItem<String>(
                    value: game.id,
                    child: Text(game.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGameId = value;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
