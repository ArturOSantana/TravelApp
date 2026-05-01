import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5E35B1);

  static const Color primaryDark = Color(0xFF311B92);

  static const Color primaryLight = Color(0xFF9575CD);

  static const Color primaryBackground = Color(0xFFF3E5F5);

  static const Color textPrimary = Color(0xFF212121);

  static const Color textSecondary = Color(0xFF5F6368);

  static const Color textDisabled = Color(0xFF9E9E9E);

  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color successBackground = Color(0xFFE8F5E9);

  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorBackground = Color(0xFFFFEBEE);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningBackground = Color(0xFFFFF3E0);

  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFF42A5F5);
  static const Color infoBackground = Color(0xFFE3F2FD);

//fundo
  static const Color background = Color(0xFFFAFAFA);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceVariant = Color(0xFFF5F5F5);

  static const Color divider = Color(0xFFE0E0E0);

  static const Color overlay = Color(0x80000000);

  // Cces para categorias de viagem
  static const Color leisure = Color(0xFF7B1FA2);
  static const Color business = Color(0xFF1976D2);
  static const Color adventure = Color(0xFFE64A19);
  static const Color family = Color(0xFF388E3C);

  static const Color statusPlanned = Color(0xFFFF9800);
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusCompleted = Color(0xFF757575);

//cores do tema dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color.fromARGB(255, 255, 255, 255);
  static const Color darkDivider = Color.fromARGB(255, 255, 255, 255);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC62828), Color(0xFFEF5350)],
  );

  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static Color withAccessibleOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.6, 1.0));
  }

  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnDark;
  }

  static bool hasAdequateContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    final contrast = (lighter + 0.05) / (darker + 0.05);

    return contrast >= 4.5;
  }
}
