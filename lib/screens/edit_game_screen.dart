import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';
import '../components/neon_text_field.dart';
import '../services/game_service.dart';
import '../models/game.dart';

/// Tela para adicionar ou editar um jogo
/// 
/// Se receber um Game, está em modo edição.
/// Caso contrário, está em modo criação.
class EditGameScreen extends StatefulWidget {
  final Game? game;

  const EditGameScreen({super.key, this.game});

  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  final _gameService = GameService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _playTimeController = TextEditingController();
  
  // Estado
  String? _selectedParentGameId;
  List<Game> _baseGames = [];
  bool _isLoading = false;
  bool _isLoadingGames = true;
  
  // Estado da imagem
  File? _selectedImageFile;
  String? _currentImageUrl; // URL da imagem atual (se editando)
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadBaseGames();
    if (widget.game != null) {
      _loadGameData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _playTimeController.dispose();
    super.dispose();
  }

  /// Carrega os jogos base para o dropdown de expansões
  Future<void> _loadBaseGames() async {
    try {
      final games = await _gameService.getBaseGames();
      setState(() {
        _baseGames = games;
        _isLoadingGames = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  /// Carrega os dados do jogo para edição
  void _loadGameData() {
    final game = widget.game!;
    _nameController.text = game.name;
    _descriptionController.text = game.description ?? '';
    _minPlayersController.text = game.minPlayers?.toString() ?? '';
    _maxPlayersController.text = game.maxPlayers?.toString() ?? '';
    _playTimeController.text = game.playTimeMinutes?.toString() ?? '';
    _selectedParentGameId = game.parentGameId;
    _currentImageUrl = game.imageUrl;
  }

  /// Seleciona uma imagem da galeria ou câmera (mobile) ou do sistema de arquivos (desktop)
  Future<void> _selectImage() async {
    try {
      File? pickedFile;

      // Detecta a plataforma
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: usa file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          pickedFile = File(result.files.single.path!);
        }
      } else {
        // Mobile: usa image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          pickedFile = File(image.path);
        }
      }

      if (pickedFile != null) {
        // Valida o tamanho do arquivo (máximo 5MB)
        final fileSize = await pickedFile.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagem muito grande. Tamanho máximo: 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImageFile = pickedFile;
          _currentImageUrl = null; // Limpa a URL atual ao selecionar nova imagem
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Salva o jogo (cria ou atualiza)
  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isUploadingImage = _selectedImageFile != null;
    });

    try {
      String? imageUrl = _currentImageUrl;

      // Se uma nova imagem foi selecionada, faz upload
      if (_selectedImageFile != null) {
        try {
          // Gera um ID temporário se for criação
          final gameId = widget.game?.id ?? const Uuid().v4();
          
          // Faz upload da imagem
          imageUrl = await _gameService.uploadGameImage(
            gameId,
            _selectedImageFile!,
          );
          
          setState(() {
            _isUploadingImage = false;
          });
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao fazer upload da imagem: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final now = DateTime.now();
      final game = Game(
        id: widget.game?.id ?? const Uuid().v4(),
        userId: widget.game?.userId ?? '', // Será preenchido pelo service
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        minPlayers: _minPlayersController.text.isEmpty
            ? null
            : int.tryParse(_minPlayersController.text),
        maxPlayers: _maxPlayersController.text.isEmpty
            ? null
            : int.tryParse(_maxPlayersController.text),
        playTimeMinutes: _playTimeController.text.isEmpty
            ? null
            : int.tryParse(_playTimeController.text),
        imageUrl: imageUrl,
        parentGameId: _selectedParentGameId,
        createdAt: widget.game?.createdAt ?? now,
      );

      if (widget.game == null) {
        await _gameService.addGame(game);
      } else {
        await _gameService.updateGame(game);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.game == null
                  ? 'Jogo adicionado com sucesso!'
                  : 'Jogo atualizado com sucesso!',
            ),
            backgroundColor: NeonTheme.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar jogo: ${e.toString()}'),
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
    final isEditMode = widget.game != null;

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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          isEditMode ? 'Editar Jogo' : 'Adicionar Jogo',
                          style: NeonTheme.titleStyle,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Preencha as informações do jogo.',
                          style: NeonTheme.subtitleStyle,
                        ),
                        const SizedBox(height: 48),
                        
                        // Seção de imagem
                        _buildImageSection(),
                        
                        const SizedBox(height: 32),
                        
                        NeonTextField(
                          label: 'Nome do jogo',
                          icon: Icons.sports_esports,
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nome do jogo é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        NeonTextField(
                          label: 'Descrição (opcional)',
                          icon: Icons.description,
                          controller: _descriptionController,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: NeonTextField(
                                label: 'Min jogadores',
                                icon: Icons.people,
                                controller: _minPlayersController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1) {
                                      return 'Número inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: NeonTextField(
                                label: 'Max jogadores',
                                icon: Icons.people_outline,
                                controller: _maxPlayersController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1) {
                                      return 'Número inválido';
                                    }
                                    if (_minPlayersController.text.isNotEmpty) {
                                      final min = int.tryParse(_minPlayersController.text);
                                      if (min != null && num < min) {
                                        return 'Deve ser >= min';
                                      }
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        NeonTextField(
                          label: 'Tempo médio (minutos)',
                          icon: Icons.access_time,
                          controller: _playTimeController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final num = int.tryParse(value);
                              if (num == null || num < 1) {
                                return 'Número inválido';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildParentGameSelector(),
                        const SizedBox(height: 48),
                        NeonButton.primary(
                          text: _isLoading
                              ? (_isUploadingImage ? 'Enviando imagem...' : 'Salvando...')
                              : 'Salvar',
                          onPressed: _isLoading ? null : _saveGame,
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

  Widget _buildParentGameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jogo base (para expansões)',
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
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
              value: _selectedParentGameId,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: NeonTheme.teal),
              dropdownColor: const Color(0xFF0A0A0F),
              style: const TextStyle(color: NeonTheme.textPrimary),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Nenhum (jogo base)'),
                ),
                ..._baseGames.map((game) => DropdownMenuItem<String>(
                      value: game.id,
                      child: Text(game.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParentGameId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói a seção de seleção de imagem
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagem do jogo',
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Preview da imagem
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.teal.withOpacity(0.4),
                width: 2,
              ),
              // Brilho sutil neon
              boxShadow: [
                BoxShadow(
                  color: NeonTheme.teal.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: _selectedImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        // Botão para selecionar imagem
        NeonButton.secondary(
          text: _selectedImageFile != null
              ? 'Trocar imagem'
              : _currentImageUrl != null
                  ? 'Trocar imagem'
                  : 'Selecionar imagem',
          onPressed: _selectImage,
          width: 200,
          height: 40,
        ),
      ],
    );
  }

  /// Constrói o placeholder da imagem
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: NeonTheme.teal.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque para\nselecionar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

