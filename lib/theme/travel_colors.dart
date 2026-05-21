import 'package:flutter/material.dart';

/// Sistema de cores único do Travel Planner
/// Baseado no mascote roxo + paleta azul/roxo moderna
///
/// Paleta Principal:
/// - Azul #2563EB (principal)
/// - Roxo #7C3AED (mascote/destaque)
/// - Branco #FFFFFF (base)
/// - Cinza #F3F4F6 (apoio)
class TravelColors {
  // ============================================================================
  // CORES DO MASCOTE - Nova Identidade
  // ============================================================================

  /// Azul principal - Cor primária do app (#2563EB)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);
  static const Color primaryBlueDark = Color(0xFF1E40AF);

  /// Roxo mascote - Cor do mascote (#7C3AED)
  static const Color mascotPurple = Color(0xFF7C3AED);
  static const Color mascotPurpleLight = Color(0xFFA78BFA);
  static const Color mascotPurpleDark = Color(0xFF6D28D9);

  // ============================================================================
  // CORES PRIMÁRIAS - Mantidas para compatibilidade
  // ============================================================================

  /// Azul céu - Alias para primaryBlue
  static const Color skyBlue = primaryBlue;
  static const Color skyBlueLight = primaryBlueLight;
  static const Color skyBlueDark = primaryBlueDark;

  /// Laranja pôr do sol - Cor de destaque e ações importantes
  static const Color sunsetOrange = Color(0xFFFF6B6B);
  static const Color sunsetOrangeLight = Color(0xFFFF9999);
  static const Color sunsetOrangeDark = Color(0xFFCC5555);

  /// Verde natureza - Sucesso, confirmações, positivo
  static const Color forestGreen = Color(0xFF51CF66);
  static const Color forestGreenLight = Color(0xFF7FE099);
  static const Color forestGreenDark = Color(0xFF3DA652);

  /// Bege areia - Backgrounds suaves, cards
  static const Color sandBeige = Color(0xFFF4E4C1);
  static const Color sandBeigeLight = Color(0xFFFFF5E1);
  static const Color sandBeigeDark = Color(0xFFE0D0A7);

  // ============================================================================
  // CORES SECUNDÁRIAS
  // ============================================================================

  /// Azul oceano profundo - Textos importantes, headers
  static const Color deepOcean = Color(0xFF1A535C);
  static const Color deepOceanLight = Color(0xFF2A6B76);
  static const Color deepOceanDark = Color(0xFF0F3A42);

  /// Amarelo areia quente - Alertas, avisos, Premium
  static const Color warmSand = Color(0xFFFFE66D);
  static const Color warmSandLight = Color(0xFFFFF09A);
  static const Color warmSandDark = Color(0xFFCCB857);

  /// Coral - Ações secundárias, links (agora alias para mascotPurple)
  static const Color coral = mascotPurple;
  static const Color coralLight = mascotPurpleLight;
  static const Color coralDark = mascotPurpleDark;

  /// Turquesa - Informações, dicas
  static const Color turquoise = Color(0xFF4DD0E1);
  static const Color turquoiseLight = Color(0xFF7AE0ED);
  static const Color turquoiseDark = Color(0xFF3AA6B4);

  // ============================================================================
  // CORES NEUTRAS
  // ============================================================================

  /// Branco nuvem - Background principal (#FFFFFF)
  static const Color cloudWhite = Color(0xFFFFFFFF);
  static const Color cloudWhiteLight = Color(0xFFFFFFFF);
  static const Color cloudWhiteDark = Color(0xFFF3F4F6);

  /// Cinza pedra - Textos secundários, ícones
  static const Color stoneGray = Color(0xFF6C757D);
  static const Color stoneGrayLight = Color(0xFF8E9BA6);
  static const Color stoneGrayDark = Color(0xFF495057);

  /// Preto noite - Textos principais
  static const Color nightBlack = Color(0xFF212529);
  static const Color nightBlackLight = Color(0xFF343A40);
  static const Color nightBlackDark = Color(0xFF000000);

  // ============================================================================
  // CORES SEMÂNTICAS
  // ============================================================================

  /// Sucesso - Operações bem-sucedidas
  static const Color success = forestGreen;
  static const Color successLight = forestGreenLight;
  static const Color successDark = forestGreenDark;
  static const Color successBackground = Color(0xFFD1FAE5);

  /// Erro - Erros, alertas críticos
  static const Color error = sunsetOrange;
  static const Color errorLight = sunsetOrangeLight;
  static const Color errorDark = sunsetOrangeDark;
  static const Color errorBackground = Color(0xFFFEE2E2);

  /// Aviso - Avisos, atenção
  static const Color warning = warmSand;
  static const Color warningLight = warmSandLight;
  static const Color warningDark = warmSandDark;
  static const Color warningBackground = Color(0xFFFEF3C7);

  /// Informação - Dicas, informações
  static const Color info = turquoise;
  static const Color infoLight = turquoiseLight;
  static const Color infoDark = turquoiseDark;
  static const Color infoBackground = Color(0xFFDBEAFE);

  // ============================================================================
  // CORES ESPECIAIS
  // ============================================================================

  /// Premium - Gradiente roxo/dourado (com mascote)
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [mascotPurple, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sombras
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // ============================================================================
  // CORES DE CONTEXTO
  // ============================================================================

  /// Grupo - Viagens em grupo
  static const Color group = coral;
  static const Color groupLight = coralLight;
  static const Color groupDark = coralDark;

  /// Solo - Viagens solo
  static const Color solo = skyBlue;
  static const Color soloLight = skyBlueLight;
  static const Color soloDark = skyBlueDark;

  // ============================================================================
  // GRADIENTES
  // ============================================================================

  /// Gradiente principal - Azul para Roxo (mascote)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, mascotPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente secundário - Oceano profundo
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [deepOcean, turquoise],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente suave - Background cards
  static const LinearGradient softGradient = LinearGradient(
    colors: [cloudWhite, sandBeigeLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente roxo suave - Para elementos do mascote
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [mascotPurpleLight, mascotPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente azul suave - Para elementos principais
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlueLight, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // CORES DE SUPERFÍCIE
  // ============================================================================

  /// Surface - Superfícies de cards e containers
  static const Color surface = cloudWhiteLight;
  static const Color surfaceVariant = sandBeige;
  static const Color surfaceTint = skyBlue;

  /// On Surface - Textos em superfícies
  static const Color onSurface = nightBlack;
  static const Color onSurfaceVariant = deepOcean;

  // ============================================================================
  // CORES DE TEXTO
  // ============================================================================

  /// Texto principal
  static const Color textPrimary = nightBlack;
  static const Color textSecondary = stoneGray;
  static const Color textTertiary = stoneGrayLight;

  /// Texto em fundos coloridos
  static const Color textOnPrimary = cloudWhiteLight;
  static const Color textOnSecondary = cloudWhiteLight;

  // ============================================================================
  // SOMBRAS E OVERLAYS - Aliases adicionais
  // ============================================================================

  /// Sombras para listas
  static final List<BoxShadow> softShadow = [
    const BoxShadow(
      color: shadowLight,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> mediumShadow = [
    const BoxShadow(
      color: shadowMedium,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> coloredShadow = [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Overlay escuro
  static const Color darkOverlay = Color(0x80000000);

  /// Cor premium (alias para mascotPurple)
  static const Color premium = mascotPurple;
}

// Made with Bob
