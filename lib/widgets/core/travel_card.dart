import 'package:flutter/material.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';

/// Card customizado do Travel Planner
///
/// Substitui Container genérico com BoxDecoration
/// Oferece variações de estilo e comportamento
class TravelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final TravelCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool elevated;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? customShadow;

  const TravelCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.variant = TravelCardVariant.standard,
    this.onTap,
    this.onLongPress,
    this.elevated = true,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.customShadow,
  });

  /// Card padrão - Uso geral
  factory TravelCard.standard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.standard,
      padding: padding,
      margin: margin,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card elevado - Destaque
  factory TravelCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.elevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card com gradiente - Premium, destaque especial
  factory TravelCard.gradient({
    required Widget child,
    Gradient? gradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.gradient,
      gradient: gradient ?? TravelColors.primaryGradient,
      padding: padding,
      margin: margin,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card outlined - Sutil, sem sombra
  factory TravelCard.outlined({
    required Widget child,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.outlined,
      border: Border.all(
        color: borderColor ?? TravelColors.stoneGrayLight,
        width: 1.5,
      ),
      elevated: false,
      padding: padding,
      margin: margin,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card flat - Sem sombra, sem borda
  factory TravelCard.flat({
    required Widget child,
    Color? color,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.flat,
      color: color,
      elevated: false,
      padding: padding,
      margin: margin,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card de viagem - Estilo específico para cards de viagem
  factory TravelCard.trip({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.trip,
      padding: padding ?? EdgeInsets.all(TravelSpacing.md),
      margin: margin ?? EdgeInsets.all(TravelSpacing.cardSpacing),
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Card de despesa - Estilo específico para cards de despesa
  factory TravelCard.expense({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return TravelCard(
      variant: TravelCardVariant.expense,
      padding: padding ?? EdgeInsets.all(TravelSpacing.md),
      margin: margin ??
          EdgeInsets.symmetric(
            horizontal: TravelSpacing.md,
            vertical: TravelSpacing.sm,
          ),
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.all(TravelSpacing.md);
    final effectiveMargin = margin ?? EdgeInsets.all(TravelSpacing.cardSpacing);
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(
          variant == TravelCardVariant.trip
              ? TravelSpacing.radiusXl
              : TravelSpacing.radiusLg,
        );

    // Determina cor baseada na variante
    Color? effectiveColor = color;
    if (effectiveColor == null) {
      switch (variant) {
        case TravelCardVariant.standard:
        case TravelCardVariant.elevated:
        case TravelCardVariant.outlined:
        case TravelCardVariant.flat:
          effectiveColor = TravelColors.cloudWhiteLight;
          break;
        case TravelCardVariant.trip:
          effectiveColor = TravelColors.cloudWhiteLight;
          break;
        case TravelCardVariant.expense:
          effectiveColor = TravelColors.sandBeigeLight;
          break;
        case TravelCardVariant.gradient:
          effectiveColor = null; // Usa gradiente
          break;
      }
    }

    // Determina sombra baseada na variante
    List<BoxShadow>? effectiveShadow = customShadow;
    if (effectiveShadow == null && elevated) {
      switch (variant) {
        case TravelCardVariant.standard:
        case TravelCardVariant.trip:
        case TravelCardVariant.expense:
          effectiveShadow = TravelColors.softShadow;
          break;
        case TravelCardVariant.elevated:
          effectiveShadow = TravelColors.mediumShadow;
          break;
        case TravelCardVariant.gradient:
          effectiveShadow = TravelColors.coloredShadow;
          break;
        case TravelCardVariant.outlined:
        case TravelCardVariant.flat:
          effectiveShadow = null;
          break;
      }
    }

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        border: border,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    // Se tem onTap ou onLongPress, envolve em InkWell
    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Variantes de estilo do TravelCard
enum TravelCardVariant {
  /// Card padrão - Uso geral
  standard,

  /// Card elevado - Mais destaque
  elevated,

  /// Card com gradiente - Premium
  gradient,

  /// Card outlined - Sutil
  outlined,

  /// Card flat - Sem sombra
  flat,

  /// Card de viagem - Estilo específico
  trip,

  /// Card de despesa - Estilo específico
  expense,
}

// Made with Bob
