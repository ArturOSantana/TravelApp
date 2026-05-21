/// Sistema de espaçamento consistente do Travel Planner
///
/// Substitui valores aleatórios (8, 10, 15, 16, 20, 24, 30, 40, 48)
/// por um sistema baseado em múltiplos de 4
class TravelSpacing {
  // ============================================================================
  // ESPAÇAMENTOS BASE
  // ============================================================================

  /// Extra pequeno - 4px
  /// Uso: Espaçamento mínimo entre elementos muito próximos
  static const double xs = 4.0;

  /// Pequeno - 8px
  /// Uso: Espaçamento entre ícone e texto, padding interno de chips
  static const double sm = 8.0;

  /// Médio - 16px
  /// Uso: Espaçamento padrão entre elementos, padding de cards
  static const double md = 16.0;

  /// Grande - 24px
  /// Uso: Espaçamento entre seções, margin de cards
  static const double lg = 24.0;

  /// Extra grande - 32px
  /// Uso: Espaçamento entre grupos de conteúdo, padding de páginas
  static const double xl = 32.0;

  /// Extra extra grande - 48px
  /// Uso: Espaçamento entre seções principais, headers
  static const double xxl = 48.0;

  // ============================================================================
  // ESPAÇAMENTOS ESPECÍFICOS
  // ============================================================================

  /// Espaçamento de página - Padding horizontal padrão das páginas
  static const double pagePadding = md;

  /// Espaçamento de seção - Entre seções de conteúdo
  static const double sectionSpacing = lg;

  /// Espaçamento de card - Margin entre cards em lista
  static const double cardSpacing = md;

  /// Espaçamento de item - Entre itens em lista
  static const double itemSpacing = sm;

  /// Espaçamento de botão - Padding interno de botões
  static const double buttonPadding = md;

  /// Espaçamento de campo - Entre campos de formulário
  static const double fieldSpacing = md;

  /// Espaçamento de ícone - Entre ícone e texto
  static const double iconSpacing = sm;

  /// Espaçamento de chip - Padding interno de chips/tags
  static const double chipPadding = sm;

  /// Espaçamento de modal - Padding de modals/dialogs
  static const double modalPadding = lg;

  /// Espaçamento de header - Padding de headers/AppBar
  static const double headerPadding = md;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Radius extra pequeno - 4px
  /// Uso: Chips, tags pequenas
  static const double radiusXs = 4.0;

  /// Radius pequeno - 8px
  /// Uso: Botões pequenos, badges
  static const double radiusSm = 8.0;

  /// Radius médio - 12px
  /// Uso: Campos de texto, botões padrão
  static const double radiusMd = 12.0;

  /// Radius grande - 16px
  /// Uso: Cards, containers
  static const double radiusLg = 16.0;

  /// Radius extra grande - 24px
  /// Uso: Cards destacados, modals
  static const double radiusXl = 24.0;

  /// Radius circular - 999px
  /// Uso: Avatares, botões circulares
  static const double radiusCircular = 999.0;

  // ============================================================================
  // ELEVAÇÕES (para Material Design)
  // ============================================================================

  /// Sem elevação
  static const double elevationNone = 0.0;

  /// Elevação baixa - Cards em repouso
  static const double elevationLow = 2.0;

  /// Elevação média - Cards hover, botões
  static const double elevationMedium = 4.0;

  /// Elevação alta - Modals, FAB
  static const double elevationHigh = 8.0;

  /// Elevação muito alta - Dialogs importantes
  static const double elevationVeryHigh = 16.0;

  // ============================================================================
  // TAMANHOS DE ÍCONES
  // ============================================================================

  /// Ícone extra pequeno - 16px
  static const double iconXs = 16.0;

  /// Ícone pequeno - 20px
  static const double iconSm = 20.0;

  /// Ícone médio - 24px (padrão Material)
  static const double iconMd = 24.0;

  /// Ícone grande - 32px
  static const double iconLg = 32.0;

  /// Ícone extra grande - 48px
  static const double iconXl = 48.0;

  /// Ícone gigante - 64px (ilustrações)
  static const double iconXxl = 64.0;

  // ============================================================================
  // TAMANHOS DE AVATAR
  // ============================================================================

  /// Avatar extra pequeno - 24px
  static const double avatarXs = 24.0;

  /// Avatar pequeno - 32px
  static const double avatarSm = 32.0;

  /// Avatar médio - 40px
  static const double avatarMd = 40.0;

  /// Avatar grande - 56px
  static const double avatarLg = 56.0;

  /// Avatar extra grande - 80px
  static const double avatarXl = 80.0;

  /// Avatar gigante - 120px (perfil)
  static const double avatarXxl = 120.0;

  // ============================================================================
  // ALTURAS DE COMPONENTES
  // ============================================================================

  /// Altura de botão pequeno
  static const double buttonHeightSm = 36.0;

  /// Altura de botão médio (padrão)
  static const double buttonHeightMd = 48.0;

  /// Altura de botão grande
  static const double buttonHeightLg = 56.0;

  /// Altura de campo de texto
  static const double textFieldHeight = 56.0;

  /// Altura de AppBar
  static const double appBarHeight = 56.0;

  /// Altura de TabBar
  static const double tabBarHeight = 48.0;

  /// Altura de BottomNavigationBar
  static const double bottomNavHeight = 56.0;

  /// Altura de ListTile
  static const double listTileHeight = 56.0;

  /// Altura de Chip
  static const double chipHeight = 32.0;

  // ============================================================================
  // LARGURAS
  // ============================================================================

  /// Largura máxima de conteúdo (para tablets/desktop)
  static const double maxContentWidth = 600.0;

  /// Largura de sidebar (para desktop)
  static const double sidebarWidth = 280.0;

  /// Largura de drawer
  static const double drawerWidth = 304.0;

  /// Largura mínima de card
  static const double cardMinWidth = 280.0;

  /// Largura máxima de card
  static const double cardMaxWidth = 400.0;

  // ============================================================================
  // BREAKPOINTS (Responsividade)
  // ============================================================================

  /// Mobile pequeno
  static const double breakpointXs = 320.0;

  /// Mobile padrão
  static const double breakpointSm = 480.0;

  /// Tablet
  static const double breakpointMd = 768.0;

  /// Desktop pequeno
  static const double breakpointLg = 1024.0;

  /// Desktop grande
  static const double breakpointXl = 1440.0;

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Retorna espaçamento baseado em múltiplo de 4
  static double custom(int multiplier) {
    return (multiplier * 4).toDouble();
  }

  /// Retorna espaçamento horizontal
  static double horizontal(double value) => value;

  /// Retorna espaçamento vertical
  static double vertical(double value) => value;

  /// Retorna padding simétrico
  static double symmetric(double value) => value;

  /// Retorna padding all
  static double all(double value) => value;

  /// Verifica se é mobile
  static bool isMobile(double width) => width < breakpointMd;

  /// Verifica se é tablet
  static bool isTablet(double width) =>
      width >= breakpointMd && width < breakpointLg;

  /// Verifica se é desktop
  static bool isDesktop(double width) => width >= breakpointLg;

  /// Retorna padding responsivo baseado na largura da tela
  static double responsivePadding(double screenWidth) {
    if (screenWidth < breakpointSm) return md;
    if (screenWidth < breakpointMd) return lg;
    if (screenWidth < breakpointLg) return xl;
    return xxl;
  }

  /// Retorna espaçamento entre cards responsivo
  static double responsiveCardSpacing(double screenWidth) {
    if (screenWidth < breakpointSm) return sm;
    if (screenWidth < breakpointMd) return md;
    return lg;
  }

  /// Retorna número de colunas para grid responsivo
  static int responsiveColumns(double screenWidth) {
    if (screenWidth < breakpointSm) return 1;
    if (screenWidth < breakpointMd) return 2;
    if (screenWidth < breakpointLg) return 3;
    return 4;
  }
}

// Made with Bob
