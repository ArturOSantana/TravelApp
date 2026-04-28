import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showBorder;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 0,
      color: backgroundColor ?? AppColors.surface,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        side: showBorder
            ? BorderSide(color: AppColors.divider, width: 1)
            : BorderSide.none,
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
    );

    if (onTap != null && semanticLabel != null) {
      return Semantics(button: true, label: semanticLabel, child: card);
    }

    return card;
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? '$title. $subtitle',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? semanticLabel;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label: $value',
      child: AccessibleCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? semanticLabel;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    this.type = AlertType.info,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getAlertConfig();

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: AccessibleCard(
        backgroundColor: config.backgroundColor,
        showBorder: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(config.icon, color: config.color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: config.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 14, color: config.color),
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: config.color,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 36),
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                color: config.color,
                tooltip: 'Fechar alerta',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ),
      ),
    );
  }

  _AlertConfig _getAlertConfig() {
    switch (type) {
      case AlertType.success:
        return _AlertConfig(
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          backgroundColor: AppColors.successBackground,
        );
      case AlertType.error:
        return _AlertConfig(
          icon: Icons.error_outline,
          color: AppColors.error,
          backgroundColor: AppColors.errorBackground,
        );
      case AlertType.warning:
        return _AlertConfig(
          icon: Icons.warning_amber_outlined,
          color: AppColors.warning,
          backgroundColor: AppColors.warningBackground,
        );
      case AlertType.info:
        return _AlertConfig(
          icon: Icons.info_outline,
          color: AppColors.info,
          backgroundColor: AppColors.infoBackground,
        );
    }
  }
}

enum AlertType { success, error, warning, info }

class _AlertConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  _AlertConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

