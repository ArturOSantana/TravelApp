import 'package:flutter/material.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';
import '../../theme/travel_text_styles.dart';

/// Indicador de loading customizado do Travel Planner
///
/// Substitui CircularProgressIndicator genérico
/// Oferece variações de estilo e mensagens
class TravelLoadingIndicator extends StatelessWidget {
  final String? message;
  final TravelLoadingSize size;
  final Color? color;
  final bool overlay;

  const TravelLoadingIndicator({
    super.key,
    this.message,
    this.size = TravelLoadingSize.medium,
    this.color,
    this.overlay = false,
  });

  /// Loading pequeno - Inline
  factory TravelLoadingIndicator.small({
    Color? color,
  }) {
    return TravelLoadingIndicator(
      size: TravelLoadingSize.small,
      color: color,
    );
  }

  /// Loading médio - Padrão
  factory TravelLoadingIndicator.medium({
    String? message,
    Color? color,
  }) {
    return TravelLoadingIndicator(
      message: message,
      size: TravelLoadingSize.medium,
      color: color,
    );
  }

  /// Loading grande - Tela cheia
  factory TravelLoadingIndicator.large({
    String? message,
    Color? color,
  }) {
    return TravelLoadingIndicator(
      message: message,
      size: TravelLoadingSize.large,
      color: color,
    );
  }

  /// Loading com overlay - Bloqueia interação
  factory TravelLoadingIndicator.overlay({
    String? message,
    Color? color,
  }) {
    return TravelLoadingIndicator(
      message: message,
      size: TravelLoadingSize.medium,
      color: color,
      overlay: true,
    );
  }

  /// Loading de viagem - Mensagem específica
  factory TravelLoadingIndicator.trip({
    String? message,
  }) {
    return TravelLoadingIndicator(
      message: message ?? 'Carregando viagem...',
      size: TravelLoadingSize.medium,
      color: TravelColors.skyBlue,
    );
  }

  /// Loading de sincronização
  factory TravelLoadingIndicator.syncing({
    String? message,
  }) {
    return TravelLoadingIndicator(
      message: message ?? 'Sincronizando...',
      size: TravelLoadingSize.small,
      color: TravelColors.turquoise,
    );
  }

  /// Loading de upload
  factory TravelLoadingIndicator.uploading({
    String? message,
  }) {
    return TravelLoadingIndicator(
      message: message ?? 'Enviando...',
      size: TravelLoadingSize.medium,
      color: TravelColors.sunsetOrange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double indicatorSize = _getSize();
    final Color effectiveColor = color ?? TravelColors.skyBlue;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Indicador circular
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: _getStrokeWidth(),
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),

        // Mensagem (se houver)
        if (message != null) ...[
          SizedBox(height: TravelSpacing.md),
          Text(
            message!,
            style: TravelTextStyles.bodyMedium(context).copyWith(
              color: TravelColors.stoneGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    // Se é overlay, envolve em Container com fundo
    if (overlay) {
      return Container(
        color: TravelColors.darkOverlay,
        child: Center(child: content),
      );
    }

    // Se é grande, centraliza
    if (size == TravelLoadingSize.large) {
      return Center(child: content);
    }

    return content;
  }

  double _getSize() {
    switch (size) {
      case TravelLoadingSize.small:
        return TravelSpacing.iconMd;
      case TravelLoadingSize.medium:
        return TravelSpacing.iconXl;
      case TravelLoadingSize.large:
        return TravelSpacing.iconXxl;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case TravelLoadingSize.small:
        return 2.0;
      case TravelLoadingSize.medium:
        return 3.0;
      case TravelLoadingSize.large:
        return 4.0;
    }
  }
}

/// Tamanhos de loading
enum TravelLoadingSize {
  /// Pequeno - 24px
  small,

  /// Médio - 48px
  medium,

  /// Grande - 64px
  large,
}

/// Widget de loading para páginas inteiras
class TravelLoadingPage extends StatelessWidget {
  final String? message;

  const TravelLoadingPage({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.cloudWhite,
      body: TravelLoadingIndicator.large(
        message: message ?? 'Carregando...',
      ),
    );
  }
}

/// Widget de loading para listas (shimmer effect)
class TravelLoadingList extends StatelessWidget {
  final int itemCount;

  const TravelLoadingList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(TravelSpacing.md),
      itemCount: itemCount,
      itemBuilder: (context, index) => _LoadingListItem(),
    );
  }
}

class _LoadingListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: TravelSpacing.md),
      padding: EdgeInsets.all(TravelSpacing.md),
      decoration: BoxDecoration(
        color: TravelColors.cloudWhiteLight,
        borderRadius: BorderRadius.circular(TravelSpacing.radiusLg),
        boxShadow: TravelColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: TravelColors.stoneGrayLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(TravelSpacing.radiusSm),
            ),
          ),
          SizedBox(height: TravelSpacing.sm),
          // Subtítulo
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: TravelColors.stoneGrayLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TravelSpacing.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de loading para cards
class TravelLoadingCard extends StatelessWidget {
  final double? width;
  final double? height;

  const TravelLoadingCard({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 200,
      margin: EdgeInsets.all(TravelSpacing.cardSpacing),
      padding: EdgeInsets.all(TravelSpacing.md),
      decoration: BoxDecoration(
        color: TravelColors.cloudWhiteLight,
        borderRadius: BorderRadius.circular(TravelSpacing.radiusLg),
        boxShadow: TravelColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TravelColors.stoneGrayLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
              ),
            ),
          ),
          SizedBox(height: TravelSpacing.sm),
          // Título
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: TravelColors.stoneGrayLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(TravelSpacing.radiusSm),
            ),
          ),
          SizedBox(height: TravelSpacing.xs),
          // Subtítulo
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: TravelColors.stoneGrayLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TravelSpacing.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}

// Made with Bob
