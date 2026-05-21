import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';
import '../../theme/travel_text_styles.dart';

/// Campo de texto customizado do Travel Planner
///
/// Substitui TextFormField genérico
/// Oferece variações de estilo e validações
class TravelTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final TravelTextFieldVariant variant;
  final String? helperText;
  final String? errorText;

  const TravelTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.variant = TravelTextFieldVariant.standard,
    this.helperText,
    this.errorText,
  });

  /// Campo padrão
  factory TravelTextField.standard({
    TextEditingController? controller,
    String? label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      variant: TravelTextFieldVariant.standard,
    );
  }

  /// Campo de email
  factory TravelTextField.email({
    TextEditingController? controller,
    String? label,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label ?? 'E-mail',
      hint: 'seu@email.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator ?? _emailValidator,
      onChanged: onChanged,
      semanticLabel: semanticLabel ?? 'Campo de e-mail',
      variant: TravelTextFieldVariant.email,
    );
  }

  /// Campo de senha
  factory TravelTextField.password({
    TextEditingController? controller,
    String? label,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label ?? 'Senha',
      hint: '••••••••',
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      validator: validator ?? _passwordValidator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      semanticLabel: semanticLabel ?? 'Campo de senha',
      variant: TravelTextFieldVariant.password,
    );
  }

  /// Campo de busca
  factory TravelTextField.search({
    TextEditingController? controller,
    String? hint,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      hint: hint ?? 'Buscar...',
      prefixIcon: Icons.search_outlined,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      semanticLabel: semanticLabel ?? 'Campo de busca',
      variant: TravelTextFieldVariant.search,
    );
  }

  /// Campo de texto longo (multiline)
  factory TravelTextField.multiline({
    TextEditingController? controller,
    String? label,
    String? hint,
    int maxLines = 5,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      minLines: 3,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      validator: validator,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      variant: TravelTextFieldVariant.multiline,
    );
  }

  /// Campo de número
  factory TravelTextField.number({
    TextEditingController? controller,
    String? label,
    String? hint,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon ?? Icons.numbers,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      variant: TravelTextFieldVariant.number,
    );
  }

  /// Campo de telefone
  factory TravelTextField.phone({
    TextEditingController? controller,
    String? label,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label ?? 'Telefone',
      hint: '(11) 99999-9999',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator ?? _phoneValidator,
      onChanged: onChanged,
      semanticLabel: semanticLabel ?? 'Campo de telefone',
      variant: TravelTextFieldVariant.phone,
    );
  }

  /// Campo de moeda
  factory TravelTextField.currency({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? semanticLabel,
  }) {
    return TravelTextField(
      controller: controller,
      label: label ?? 'Valor',
      hint: hint ?? '0,00',
      prefixIcon: Icons.attach_money,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      validator: validator,
      onChanged: onChanged,
      semanticLabel: semanticLabel ?? 'Campo de valor monetário',
      variant: TravelTextFieldVariant.currency,
    );
  }

  @override
  State<TravelTextField> createState() => _TravelTextFieldState();

  // Validadores padrão
  static String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe seu e-mail';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha';
    }
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe seu telefone';
    }
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 11) {
      return 'Telefone inválido (use 11 dígitos)';
    }
    return null;
  }
}

class _TravelTextFieldState extends State<TravelTextField> {
  bool _obscureText = false;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determina cor baseada no estado
    Color borderColor = TravelColors.stoneGrayLight;
    if (_isFocused) {
      borderColor = TravelColors.skyBlue;
    }
    if (widget.errorText != null) {
      borderColor = TravelColors.error;
    }

    // Suffix icon para senha
    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.variant == TravelTextFieldVariant.password) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: TravelColors.stoneGray,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
      );
    }

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.label,
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        style: TravelTextStyles.fieldText(context),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TravelTextStyles.fieldLabel(context),
          hintText: widget.hint,
          hintStyle: TravelTextStyles.fieldHint(context),
          helperText: widget.helperText,
          helperStyle: TravelTextStyles.labelSmall(context),
          errorText: widget.errorText,
          errorStyle: TravelTextStyles.fieldError(context),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused
                      ? TravelColors.skyBlue
                      : TravelColors.stoneGray,
                  size: TravelSpacing.iconMd,
                )
              : null,
          suffixIcon: effectiveSuffixIcon,
          filled: true,
          fillColor: widget.enabled
              ? TravelColors.cloudWhiteLight
              : TravelColors.stoneGrayLight.withOpacity(0.3),
          contentPadding: EdgeInsets.all(TravelSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: TravelColors.stoneGrayLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: TravelColors.skyBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: TravelColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: TravelColors.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            borderSide: BorderSide(color: TravelColors.stoneGrayLight),
          ),
        ),
      ),
    );
  }
}

/// Variantes de campo de texto
enum TravelTextFieldVariant {
  /// Campo padrão
  standard,

  /// Campo de email
  email,

  /// Campo de senha
  password,

  /// Campo de busca
  search,

  /// Campo multiline
  multiline,

  /// Campo de número
  number,

  /// Campo de telefone
  phone,

  /// Campo de moeda
  currency,
}

// Made with Bob
