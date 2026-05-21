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

  static double _scaledSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final clampedFactor = textScaleFactor.clamp(
      _minScaleFactor,
      _maxScaleFactor,
    );
    return baseSize * clampedFactor;
  }

  static double fixedSize(double size) => size;

  static double getLineHeight(double fontSize) {
    // Regra geral: fontes menores precisam de mais espaço
    if (fontSize <= 12) return 1.6;
    if (fontSize <= 16) return 1.5;
    if (fontSize <= 24) return 1.4;
    return 1.3;
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

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

  static bool isAccessibleSize(double fontSize) {
    return fontSize >= 12.0;
  }

  static bool hasAccessibleContrast(Color textColor, Color backgroundColor) {
    return AppColors.hasAdequateContrast(textColor, backgroundColor);
  }

  static double getMinimumAccessibleSize(String context) {
    switch (context) {
      case 'button':
        return 16.0; // Botões devem ter no mínimo 16sp
      case 'body':
        return 16.0; // Texto de corpo deve ter no mínimo 16sp
      case 'caption':
        return 12.0; 
      default:
        return 14.0; // Padrão seguro
    }
  }
}
