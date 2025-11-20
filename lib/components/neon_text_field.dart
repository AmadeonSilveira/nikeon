import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Campo de texto neon reutilizável
/// 
/// Componente de input com borda neon, brilho sutil e ícone opcional.
/// Mantém consistência visual com o tema neon gamer premium.
class NeonTextField extends StatefulWidget {
  /// Texto do label/hint
  final String label;
  
  /// Ícone exibido no início do campo
  final IconData? icon;
  
  /// Se o campo é para senha (oculta o texto)
  final bool obscureText;
  
  /// Se deve mostrar botão de toggle para senha (apenas se obscureText for true)
  final bool showPasswordToggle;
  
  /// Controlador do texto (opcional)
  final TextEditingController? controller;
  
  /// Validador do texto (opcional)
  final String? Function(String?)? validator;
  
  /// Tipo de teclado
  final TextInputType? keyboardType;
  
  /// FocusNode externo (opcional, se não fornecido cria um interno)
  final FocusNode? focusNode;

  const NeonTextField({
    super.key,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.focusNode,
  });

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  bool _isFocused = false;
  bool _obscureText = true;
  late final FocusNode _focusNode;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    
    // Usa o FocusNode fornecido ou cria um interno
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Só dispõe se for o FocusNode interno
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Brilho sutil quando focado
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: NeonTheme.teal.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText && _obscureText,
        focusNode: _focusNode,
        style: const TextStyle(
          color: NeonTheme.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused
                ? NeonTheme.teal
                : NeonTheme.textSecondary,
          ),
          hintText: widget.label,
          hintStyle: const TextStyle(
            color: NeonTheme.textSecondary,
          ),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: _isFocused
                      ? NeonTheme.teal
                      : NeonTheme.textSecondary,
                )
              : null,
          suffixIcon: widget.showPasswordToggle && widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _isFocused
                        ? NeonTheme.teal
                        : NeonTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          // Borda neon sutil
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: NeonTheme.teal.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          // Borda neon mais intensa quando focado
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: NeonTheme.teal,
              width: 2,
            ),
          ),
          // Borda de erro (se houver validação)
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

