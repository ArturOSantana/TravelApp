import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Determina as dimensões baseado no tamanho
    final double height = _getHeight();
    final double minWidth = _getMinWidth();
    final double fontSize = _getFontSize();
    final EdgeInsets padding = _getPadding();

    // Conteúdo do botão
    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForegroundColor(context),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    // Wrapper com Semantics
    Widget button = Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        height: height,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: _buildButton(context, content, padding),
        ),
      ),
    );

    return button;
  }

  Widget _buildButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
  ) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.textDisabled,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: content,
        );

      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: 1.5,
            ),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: content,
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: content,
        );

      case ButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.error,
            foregroundColor: foregroundColor ?? Colors.white,
            disabledBackgroundColor: AppColors.textDisabled,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: content,
        );

      case ButtonType.success:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.success,
            foregroundColor: foregroundColor ?? Colors.white,
            disabledBackgroundColor: AppColors.textDisabled,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: content,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48; // WCAG mínimo
      case ButtonSize.large:
        return 56;
    }
  }

  double _getMinWidth() {
    switch (size) {
      case ButtonSize.small:
        return 80;
      case ButtonSize.medium:
        return 88; // WCAG mínimo
      case ButtonSize.large:
        return 120;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  Color _getForegroundColor(BuildContext context) {
    if (foregroundColor != null) return foregroundColor!;

    switch (type) {
      case ButtonType.primary:
      case ButtonType.danger:
      case ButtonType.success:
        return Colors.white;
      case ButtonType.secondary:
      case ButtonType.text:
        return AppColors.primary;
    }
  }
}

enum ButtonType { primary, secondary, text, danger, success }

enum ButtonSize { small, medium, large }

class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double size;
  final String? semanticLabel;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.size = 24,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color ?? AppColors.textPrimary,
        constraints: const BoxConstraints(
          minWidth: 48, // WCAG mínimo
          minHeight: 48, // WCAG mínimo
        ),
        splashRadius: 24,
      ),
    );
  }
}

/// Floating Action Button acessível
class AccessibleFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const AccessibleFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: label,
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
        mini: mini,
        child: Icon(icon, size: mini ? 20 : 24),
      ),
    );
  }
}

class AccessibleExtendedFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AccessibleExtendedFAB({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
      ),
    );
  }
}
