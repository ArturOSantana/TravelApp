import 'package:flutter/material.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';
import '../../theme/travel_text_styles.dart';

/// AppBar customizado do Travel Planner
///
/// Substitui AppBar genérico
/// Oferece variações de estilo consistentes
class TravelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final TravelAppBarVariant variant;
  final VoidCallback? onBackPressed;

  const TravelAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.variant = TravelAppBarVariant.standard,
    this.onBackPressed,
  });

  /// AppBar padrão
  factory TravelAppBar.standard({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
  }) {
    return TravelAppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      variant: TravelAppBarVariant.standard,
    );
  }

  /// AppBar com gradiente
  factory TravelAppBar.gradient({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
  }) {
    return TravelAppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      variant: TravelAppBarVariant.gradient,
    );
  }

  /// AppBar transparente (para telas com imagem de fundo)
  factory TravelAppBar.transparent({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
  }) {
    return TravelAppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      variant: TravelAppBarVariant.transparent,
    );
  }

  /// AppBar de busca
  factory TravelAppBar.search({
    required Widget searchField,
    List<Widget>? actions,
  }) {
    return TravelAppBar(
      title: '',
      actions: actions,
      variant: TravelAppBarVariant.search,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(TravelSpacing.appBarHeight),
        child: Padding(
          padding: EdgeInsets.all(TravelSpacing.md),
          child: searchField,
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    double height = TravelSpacing.appBarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    // Determina cores baseadas na variante
    Color? effectiveBackgroundColor = backgroundColor;
    Color? effectiveForegroundColor = foregroundColor;
    double effectiveElevation = elevation ?? TravelSpacing.elevationNone;

    switch (variant) {
      case TravelAppBarVariant.standard:
        effectiveBackgroundColor ??= TravelColors.cloudWhiteLight;
        effectiveForegroundColor ??= TravelColors.nightBlack;
        break;
      case TravelAppBarVariant.gradient:
        effectiveBackgroundColor = Colors.transparent;
        effectiveForegroundColor ??= TravelColors.cloudWhite;
        effectiveElevation = 0;
        break;
      case TravelAppBarVariant.transparent:
        effectiveBackgroundColor = Colors.transparent;
        effectiveForegroundColor ??= TravelColors.cloudWhite;
        effectiveElevation = 0;
        break;
      case TravelAppBarVariant.search:
        effectiveBackgroundColor ??= TravelColors.cloudWhiteLight;
        effectiveForegroundColor ??= TravelColors.nightBlack;
        break;
    }

    Widget appBar = AppBar(
      title: Semantics(
        header: true,
        child: Text(
          title,
          style: TravelTextStyles.titleLarge(
            context,
            color: effectiveForegroundColor,
          ),
        ),
      ),
      centerTitle: centerTitle,
      elevation: effectiveElevation,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      surfaceTintColor: Colors.transparent,
      leading: leading ??
          (onBackPressed != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: onBackPressed,
                  tooltip: 'Voltar',
                )
              : null),
      actions: actions,
      bottom: bottom,
      iconTheme: IconThemeData(
        color: effectiveForegroundColor,
        size: TravelSpacing.iconMd,
      ),
    );

    // Se é gradiente, envolve em Container com gradiente
    if (variant == TravelAppBarVariant.gradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: TravelColors.primaryGradient,
        ),
        child: appBar,
      );
    }

    return appBar;
  }
}

/// Variantes de AppBar
enum TravelAppBarVariant {
  /// AppBar padrão
  standard,

  /// AppBar com gradiente
  gradient,

  /// AppBar transparente
  transparent,

  /// AppBar de busca
  search,
}

// Made with Bob
