import 'package:flutter/material.dart';
import 'travel_colors.dart';

/// Sistema de tipografia único do Travel Planner
///
/// Substitui AppTextStyles genérico por estilos com personalidade
/// Baseado em Material Design 3 com customizações
class TravelTextStyles {
  // ============================================================================
  // FAMÍLIA DE FONTES
  // ============================================================================

  /// Fonte principal - Para títulos e destaques
  static const String primaryFont = 'Poppins';

  /// Fonte secundária - Para corpo de texto
  static const String secondaryFont = 'Inter';

  /// Fonte mono - Para códigos e números
  static const String monoFont = 'RobotoMono';

  // ============================================================================
  // DISPLAY - Títulos muito grandes (Hero sections)
  // ============================================================================

  /// Display Large - 57px
  /// Uso: Hero sections, splash screens
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 57,
      fontWeight: FontWeight.w800,
      height: 1.12,
      letterSpacing: -0.25,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Display Medium - 45px
  /// Uso: Títulos de página principais
  static TextStyle displayMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 45,
      fontWeight: FontWeight.w700,
      height: 1.16,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Display Small - 36px
  /// Uso: Títulos de seção importantes
  static TextStyle displaySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      height: 1.22,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  // ============================================================================
  // HEADLINE - Títulos de seção
  // ============================================================================

  /// Headline Large - 32px
  /// Uso: Títulos de página secundários
  static TextStyle headlineLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Headline Medium - 28px
  /// Uso: Títulos de cards importantes
  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Headline Small - 24px
  /// Uso: Subtítulos de seção
  static TextStyle headlineSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  // ============================================================================
  // TITLE - Títulos de componentes
  // ============================================================================

  /// Title Large - 22px
  /// Uso: Títulos de AppBar, dialogs
  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Title Medium - 16px
  /// Uso: Títulos de cards, list tiles
  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Title Small - 14px
  /// Uso: Subtítulos de cards
  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: color ?? TravelColors.nightBlack,
    );
  }

  // ============================================================================
  // BODY - Texto de corpo
  // ============================================================================

  /// Body Large - 16px
  /// Uso: Texto principal de conteúdo
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Body Medium - 14px
  /// Uso: Texto padrão de corpo
  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Body Small - 12px
  /// Uso: Texto secundário, descrições
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: color ?? TravelColors.stoneGray,
    );
  }

  // ============================================================================
  // LABEL - Textos de UI
  // ============================================================================

  /// Label Large - 14px
  /// Uso: Botões, tabs
  static TextStyle labelLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Label Medium - 12px
  /// Uso: Chips, badges
  static TextStyle labelMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Label Small - 11px
  /// Uso: Hints, captions
  static TextStyle labelSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.5,
      color: color ?? TravelColors.stoneGray,
    );
  }

  // ============================================================================
  // ESTILOS ESPECIAIS
  // ============================================================================

  /// Mono - Para códigos, números
  static TextStyle mono(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: monoFont,
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
      color: color ?? TravelColors.nightBlack,
    );
  }

  /// Preço - Para valores monetários
  static TextStyle price(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: fontSize ?? 24,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: color ?? TravelColors.skyBlue,
    );
  }

  /// Número grande - Para estatísticas
  static TextStyle bigNumber(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: fontSize ?? 48,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -1,
      color: color ?? TravelColors.skyBlue,
    );
  }

  /// Destaque - Para textos importantes
  static TextStyle highlight(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: fontSize ?? 16,
      fontWeight: FontWeight.w700,
      height: 1.5,
      letterSpacing: 0.5,
      color: color ?? TravelColors.sunsetOrange,
    );
  }

  /// Link - Para links clicáveis
  static TextStyle link(
    BuildContext context, {
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      decoration: TextDecoration.underline,
      color: color ?? TravelColors.skyBlue,
    );
  }

  /// Erro - Para mensagens de erro
  static TextStyle error(
    BuildContext context, {
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: fontSize ?? 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.4,
      color: TravelColors.error,
    );
  }

  /// Sucesso - Para mensagens de sucesso
  static TextStyle success(
    BuildContext context, {
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: fontSize ?? 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.4,
      color: TravelColors.success,
    );
  }

  // ============================================================================
  // ESTILOS DE BOTÃO
  // ============================================================================

  /// Botão primário
  static TextStyle buttonPrimary(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.5,
      letterSpacing: 0.5,
      color: TravelColors.cloudWhite,
    );
  }

  /// Botão secundário
  static TextStyle buttonSecondary(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.5,
      color: TravelColors.skyBlue,
    );
  }

  /// Botão texto
  static TextStyle buttonText(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: TravelColors.skyBlue,
    );
  }

  // ============================================================================
  // ESTILOS DE CAMPO
  // ============================================================================

  /// Label de campo
  static TextStyle fieldLabel(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.4,
      color: TravelColors.stoneGray,
    );
  }

  /// Texto de campo
  static TextStyle fieldText(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: TravelColors.nightBlack,
    );
  }

  /// Hint de campo
  static TextStyle fieldHint(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: TravelColors.stoneGray,
    );
  }

  /// Erro de campo
  static TextStyle fieldError(BuildContext context) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.4,
      color: TravelColors.error,
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Aplica negrito a um estilo
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  /// Aplica itálico a um estilo
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Aplica sublinhado a um estilo
  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Aplica riscado a um estilo
  static TextStyle lineThrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }

  /// Altera a cor de um estilo
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Altera o tamanho de um estilo
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Altera o peso de um estilo
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Altera a altura da linha de um estilo
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  /// Altera o espaçamento entre letras de um estilo
  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  /// Retorna estilo responsivo baseado na largura da tela
  static TextStyle responsive(
    BuildContext context,
    double screenWidth, {
    required TextStyle mobile,
    required TextStyle tablet,
    required TextStyle desktop,
  }) {
    if (screenWidth < 768) return mobile;
    if (screenWidth < 1024) return tablet;
    return desktop;
  }
}

// Made with Bob
