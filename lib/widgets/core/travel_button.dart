import 'package:flutter/material.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';
import '../../theme/travel_text_styles.dart';

/// Botão customizado do Travel Planner
///
/// Substitui ElevatedButton, OutlinedButton e TextButton genéricos
/// Oferece variações de estilo consistentes
class TravelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TravelButtonType type;
  final TravelButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool isLoading;
  final bool fullWidth;
  final Color? customColor;
  final String? semanticLabel;

  const TravelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = TravelButtonType.primary,
    this.size = TravelButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
    this.semanticLabel,
  });

  /// Botão primário - Ação principal
  factory TravelButton.primary({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.primary,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão secundário - Ação secundária
  factory TravelButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.secondary,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão outlined - Ação alternativa
  factory TravelButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.outlined,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão texto - Ação sutil
  factory TravelButton.text({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.text,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: false,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão de erro/perigo - Ações destrutivas
  factory TravelButton.danger({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.danger,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão de sucesso - Confirmações
  factory TravelButton.success({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.success,
      size: size,
      icon: icon,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  /// Botão Premium - Upgrade, recursos premium
  factory TravelButton.premium({
    required String label,
    required VoidCallback? onPressed,
    TravelButtonSize size = TravelButtonSize.medium,
    IconData? icon,
    bool iconRight = false,
    bool isLoading = false,
    bool fullWidth = false,
    String? semanticLabel,
  }) {
    return TravelButton(
      label: label,
      onPressed: onPressed,
      type: TravelButtonType.premium,
      size: size,
      icon: icon ?? Icons.workspace_premium,
      iconRight: iconRight,
      isLoading: isLoading,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina altura baseada no tamanho
    final double height = _getHeight();
    final double iconSize = _getIconSize();
    final EdgeInsets padding = _getPadding();
    final TextStyle textStyle = _getTextStyle(context);

    // Conteúdo do botão
    Widget content = _buildContent(context, textStyle, iconSize);

    // Envolve em Semantics
    content = Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: semanticLabel ?? label,
      child: content,
    );

    // Aplica fullWidth se necessário
    if (fullWidth) {
      content = SizedBox(
        width: double.infinity,
        height: height,
        child: content,
      );
    } else {
      content = SizedBox(
        height: height,
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent(
      BuildContext context, TextStyle textStyle, double iconSize) {
    // Se está loading, mostra indicador
    if (isLoading) {
      return _buildButton(
        context,
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLoadingColor(),
            ),
          ),
        ),
      );
    }

    // Conteúdo do label
    Widget labelWidget = Text(label, style: textStyle);

    // Se tem ícone, adiciona
    if (icon != null) {
      final iconWidget = Icon(icon, size: iconSize);
      final spacing = SizedBox(width: TravelSpacing.iconSpacing);

      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: iconRight
            ? [labelWidget, spacing, iconWidget]
            : [iconWidget, spacing, labelWidget],
      );
    }

    return _buildButton(context, child: labelWidget);
  }

  Widget _buildButton(BuildContext context, {required Widget child}) {
    final padding = _getPadding();

    switch (type) {
      case TravelButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? TravelColors.skyBlue,
            foregroundColor: TravelColors.cloudWhite,
            disabledBackgroundColor: TravelColors.stoneGrayLight,
            disabledForegroundColor: TravelColors.cloudWhite,
            elevation: TravelSpacing.elevationLow,
            shadowColor: (customColor ?? TravelColors.skyBlue).withOpacity(0.3),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
          ),
          child: child,
        );

      case TravelButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? TravelColors.sunsetOrange,
            foregroundColor: TravelColors.cloudWhite,
            disabledBackgroundColor: TravelColors.stoneGrayLight,
            disabledForegroundColor: TravelColors.cloudWhite,
            elevation: TravelSpacing.elevationLow,
            shadowColor:
                (customColor ?? TravelColors.sunsetOrange).withOpacity(0.3),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
          ),
          child: child,
        );

      case TravelButtonType.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? TravelColors.skyBlue,
            disabledForegroundColor: TravelColors.stoneGrayLight,
            side: BorderSide(
              color: customColor ?? TravelColors.skyBlue,
              width: 2,
            ),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
          ),
          child: child,
        );

      case TravelButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? TravelColors.skyBlue,
            disabledForegroundColor: TravelColors.stoneGrayLight,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusSm),
            ),
          ),
          child: child,
        );

      case TravelButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: TravelColors.error,
            foregroundColor: TravelColors.cloudWhite,
            disabledBackgroundColor: TravelColors.stoneGrayLight,
            disabledForegroundColor: TravelColors.cloudWhite,
            elevation: TravelSpacing.elevationLow,
            shadowColor: TravelColors.error.withOpacity(0.3),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
          ),
          child: child,
        );

      case TravelButtonType.success:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: TravelColors.success,
            foregroundColor: TravelColors.cloudWhite,
            disabledBackgroundColor: TravelColors.stoneGrayLight,
            disabledForegroundColor: TravelColors.cloudWhite,
            elevation: TravelSpacing.elevationLow,
            shadowColor: TravelColors.success.withOpacity(0.3),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
          ),
          child: child,
        );

      case TravelButtonType.premium:
        return Container(
          decoration: BoxDecoration(
            gradient: TravelColors.premiumGradient,
            borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            boxShadow: TravelColors.coloredShadow,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: TravelColors.nightBlack,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: TravelColors.stoneGray,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
              ),
            ),
            child: child,
          ),
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case TravelButtonSize.small:
        return TravelSpacing.buttonHeightSm;
      case TravelButtonSize.medium:
        return TravelSpacing.buttonHeightMd;
      case TravelButtonSize.large:
        return TravelSpacing.buttonHeightLg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case TravelButtonSize.small:
        return TravelSpacing.iconSm;
      case TravelButtonSize.medium:
        return TravelSpacing.iconMd;
      case TravelButtonSize.large:
        return TravelSpacing.iconLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case TravelButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: TravelSpacing.md,
          vertical: TravelSpacing.sm,
        );
      case TravelButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: TravelSpacing.buttonPadding,
          vertical: TravelSpacing.md,
        );
      case TravelButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: TravelSpacing.lg,
          vertical: TravelSpacing.md,
        );
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (size) {
      case TravelButtonSize.small:
        return TravelTextStyles.labelMedium(context);
      case TravelButtonSize.medium:
        return TravelTextStyles.buttonPrimary(context);
      case TravelButtonSize.large:
        return TravelTextStyles.buttonPrimary(context).copyWith(fontSize: 18);
    }
  }

  Color _getLoadingColor() {
    switch (type) {
      case TravelButtonType.primary:
      case TravelButtonType.secondary:
      case TravelButtonType.danger:
      case TravelButtonType.success:
        return TravelColors.cloudWhite;
      case TravelButtonType.outlined:
      case TravelButtonType.text:
        return customColor ?? TravelColors.skyBlue;
      case TravelButtonType.premium:
        return TravelColors.nightBlack;
    }
  }
}

/// Tipos de botão
enum TravelButtonType {
  /// Botão primário - Ação principal (azul céu)
  primary,

  /// Botão secundário - Ação secundária (laranja pôr do sol)
  secondary,

  /// Botão outlined - Ação alternativa
  outlined,

  /// Botão texto - Ação sutil
  text,

  /// Botão de erro - Ações destrutivas (vermelho)
  danger,

  /// Botão de sucesso - Confirmações (verde)
  success,

  /// Botão Premium - Upgrade (gradiente dourado)
  premium,
}

/// Tamanhos de botão
enum TravelButtonSize {
  /// Pequeno - 36px
  small,

  /// Médio - 48px (padrão)
  medium,

  /// Grande - 56px
  large,
}

// Made with Bob
