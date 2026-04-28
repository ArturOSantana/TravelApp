import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String _fontFamily = 'Roboto';
  static const double _minScaleFactor = 0.8;
  static const double _maxScaleFactor = 1.5;

  static TextStyle h1(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 32),
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.5,
      fontFamily: _fontFamily,
    );
  }

  static TextStyle h2(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 28),
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.3,
      fontFamily: _fontFamily,
    );
  }
  static TextStyle h3(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 24),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.3,
      letterSpacing: -0.2,
      fontFamily: _fontFamily,
    );
  }

  static TextStyle h4(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 20),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
      letterSpacing: 0,
      fontFamily: _fontFamily,
    );
  }

  static TextStyle h5(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 18),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.4,
      letterSpacing: 0,
      fontFamily: _fontFamily,
    );
  }

  static TextStyle h6(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 16),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.5,
      letterSpacing: 0.1,
      fontFamily: _fontFamily,
    );
  }


  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 18),
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textPrimary,
      height: 1.6,
      letterSpacing: 0.15,
      fontFamily: _fontFamily,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 16),
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textPrimary,
      height: 1.5,
      letterSpacing: 0.15,
      fontFamily: _fontFamily,
    );
  }

  /// Body Small - Texto pequeno (14sp)
  /// Uso: Texto secundário, descrições
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 14),
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textSecondary,
      height: 1.5,
      letterSpacing: 0.25,
      fontFamily: _fontFamily,
    );
  }

  // ========== LABELS E BOTÕES ==========

  /// Label Large - Label grande (16sp)
  /// Uso: Botões principais, labels importantes
  static TextStyle labelLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 16),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.25,
      letterSpacing: 0.5,
      fontFamily: _fontFamily,
    );
  }

  /// Label - Label padrão (14sp)
  /// Uso: Botões secundários, labels de formulário
  static TextStyle label(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 14),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      height: 1.25,
      letterSpacing: 0.5,
      fontFamily: _fontFamily,
    );
  }

  /// Label Small - Label pequeno (12sp)
  /// Uso: Tags, badges, labels mínimos
  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 12),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textSecondary,
      height: 1.25,
      letterSpacing: 0.5,
      fontFamily: _fontFamily,
    );
  }

  // ========== CAPTION E OVERLINE ==========

  /// Caption - Texto de legenda (12sp)
  /// Uso: Legendas, timestamps, metadados
  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 12),
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textSecondary,
      height: 1.4,
      letterSpacing: 0.4,
      fontFamily: _fontFamily,
    );
  }

  /// Overline - Texto sobrescrito (10sp)
  /// Uso: Categorias, seções, headers de tabela
  static TextStyle overline(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 10),
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textSecondary,
      height: 1.6,
      letterSpacing: 1.5,
      fontFamily: _fontFamily,
    );
  }

  // ========== ESTILOS ESPECIAIS ==========

  /// Button - Estilo para botões (16sp)
  static TextStyle button(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 16),
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textOnPrimary,
      height: 1.25,
      letterSpacing: 0.75,
      fontFamily: _fontFamily,
    );
  }

  /// Link - Estilo para links (16sp)
  static TextStyle link(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: _scaledSize(context, 16),
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.primary,
      height: 1.5,
      letterSpacing: 0.15,
      decoration: TextDecoration.underline,
      fontFamily: _fontFamily,
    );
  }

  /// Error - Estilo para mensagens de erro (14sp)
  static TextStyle error(BuildContext context) {
    return TextStyle(
      fontSize: _scaledSize(context, 14),
      fontWeight: FontWeight.w500,
      color: AppColors.error,
      height: 1.4,
      letterSpacing: 0.25,
      fontFamily: _fontFamily,
    );
  }

  /// Success - Estilo para mensagens de sucesso (14sp)
  static TextStyle success(BuildContext context) {
    return TextStyle(
      fontSize: _scaledSize(context, 14),
      fontWeight: FontWeight.w500,
      color: AppColors.success,
      height: 1.4,
      letterSpacing: 0.25,
      fontFamily: _fontFamily,
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Calcula tamanho de fonte escalável respeitando preferências do usuário
  /// Limita o fator de escala para manter legibilidade
  static double _scaledSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final clampedFactor = textScaleFactor.clamp(
      _minScaleFactor,
      _maxScaleFactor,
    );
    return baseSize * clampedFactor;
  }

  /// Retorna tamanho de fonte sem escala (para casos específicos)
  static double fixedSize(double size) => size;

  /// Calcula altura de linha ideal para um tamanho de fonte
  static double getLineHeight(double fontSize) {
    // Regra geral: fontes menores precisam de mais espaço
    if (fontSize <= 12) return 1.6;
    if (fontSize <= 16) return 1.5;
    if (fontSize <= 24) return 1.4;
    return 1.3;
  }

  /// Retorna estilo com peso customizado
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Retorna estilo com cor customizada
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Retorna estilo com decoração
  static TextStyle withDecoration(
    TextStyle style,
    TextDecoration decoration, {
    Color? decorationColor,
  }) {
    return style.copyWith(
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  // ========== VALIDAÇÃO DE ACESSIBILIDADE ==========

  /// Verifica se o tamanho de fonte é acessível (mínimo 12sp)
  static bool isAccessibleSize(double fontSize) {
    return fontSize >= 12.0;
  }

  /// Verifica se o contraste entre texto e background é adequado
  static bool hasAccessibleContrast(Color textColor, Color backgroundColor) {
    return AppColors.hasAdequateContrast(textColor, backgroundColor);
  }

  /// Retorna recomendação de tamanho mínimo para um contexto
  static double getMinimumAccessibleSize(String context) {
    switch (context) {
      case 'button':
        return 16.0; // Botões devem ter no mínimo 16sp
      case 'body':
        return 16.0; // Texto de corpo deve ter no mínimo 16sp
      case 'caption':
        return 12.0; // Legendas podem ter no mínimo 12sp
      default:
        return 14.0; // Padrão seguro
    }
  }
}

// Made with Bob
