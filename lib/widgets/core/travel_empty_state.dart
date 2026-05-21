import 'package:flutter/material.dart';
import '../../theme/travel_colors.dart';
import '../../theme/travel_spacing.dart';
import '../../theme/travel_text_styles.dart';
import 'travel_button.dart';

/// Estado vazio customizado do Travel Planner
///
/// Substitui Center + Icon + Text genérico
/// Oferece estados vazios com personalidade e call-to-action
class TravelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final TravelEmptyStateType type;
  final Widget? customIllustration;

  const TravelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.type = TravelEmptyStateType.neutral,
    this.customIllustration,
  });

  /// Estado vazio de viagens
  factory TravelEmptyState.noTrips({
    VoidCallback? onCreateTrip,
  }) {
    return TravelEmptyState(
      icon: Icons.flight_takeoff,
      title: 'Nenhuma viagem ainda',
      message:
          'Comece a planejar sua próxima aventura!\nCrie sua primeira viagem e organize tudo em um só lugar.',
      actionLabel: 'Criar Primeira Viagem',
      onAction: onCreateTrip,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado vazio de despesas
  factory TravelEmptyState.noExpenses({
    VoidCallback? onAddExpense,
  }) {
    return TravelEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Nenhuma despesa registrada',
      message:
          'Registre seus gastos para acompanhar o orçamento da viagem e dividir custos com o grupo.',
      actionLabel: 'Adicionar Despesa',
      onAction: onAddExpense,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado vazio de journal
  factory TravelEmptyState.noJournalEntries({
    VoidCallback? onCreateEntry,
  }) {
    return TravelEmptyState(
      icon: Icons.photo_library_outlined,
      title: 'Nenhum registro ainda',
      message:
          'Capture suas memórias!\nAdicione fotos e conte como está sendo sua viagem.',
      actionLabel: 'Criar Primeiro Registro',
      onAction: onCreateEntry,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado vazio de atividades
  factory TravelEmptyState.noActivities({
    VoidCallback? onAddActivity,
  }) {
    return TravelEmptyState(
      icon: Icons.event_outlined,
      title: 'Nenhuma atividade planejada',
      message:
          'Monte seu roteiro!\nAdicione atividades, passeios e compromissos ao seu itinerário.',
      actionLabel: 'Adicionar Atividade',
      onAction: onAddActivity,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado vazio de membros
  factory TravelEmptyState.noMembers({
    VoidCallback? onInviteMembers,
  }) {
    return TravelEmptyState(
      icon: Icons.group_outlined,
      title: 'Viagem solo',
      message:
          'Convide amigos e familiares para planejar juntos!\nCompartilhe despesas e organize tudo em grupo.',
      actionLabel: 'Convidar Membros',
      onAction: onInviteMembers,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado vazio de busca
  factory TravelEmptyState.noSearchResults({
    String? searchTerm,
  }) {
    return TravelEmptyState(
      icon: Icons.search_off_outlined,
      title: 'Nenhum resultado encontrado',
      message: searchTerm != null
          ? 'Não encontramos resultados para "$searchTerm".\nTente buscar com outros termos.'
          : 'Não encontramos resultados para sua busca.\nTente buscar com outros termos.',
      type: TravelEmptyStateType.neutral,
    );
  }

  /// Estado vazio de comunidade
  factory TravelEmptyState.noCommunityPosts({
    VoidCallback? onCreatePost,
  }) {
    return TravelEmptyState(
      icon: Icons.public_outlined,
      title: 'Nenhuma recomendação ainda',
      message:
          'Seja o primeiro a compartilhar!\nAjude outros viajantes com suas dicas e experiências.',
      actionLabel: 'Compartilhar Recomendação',
      onAction: onCreatePost,
      type: TravelEmptyStateType.action,
    );
  }

  /// Estado de erro genérico
  factory TravelEmptyState.error({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return TravelEmptyState(
      icon: Icons.error_outline,
      title: 'Algo deu errado',
      message: errorMessage ??
          'Não foi possível carregar os dados.\nVerifique sua conexão e tente novamente.',
      actionLabel: 'Tentar Novamente',
      onAction: onRetry,
      type: TravelEmptyStateType.error,
    );
  }

  /// Estado de sem conexão
  factory TravelEmptyState.offline({
    VoidCallback? onRetry,
  }) {
    return TravelEmptyState(
      icon: Icons.wifi_off_outlined,
      title: 'Sem conexão',
      message:
          'Você está offline.\nVerifique sua conexão com a internet e tente novamente.',
      actionLabel: 'Tentar Novamente',
      onAction: onRetry,
      type: TravelEmptyStateType.error,
    );
  }

  /// Estado de permissão negada
  factory TravelEmptyState.permissionDenied({
    required String permission,
    VoidCallback? onRequestPermission,
  }) {
    return TravelEmptyState(
      icon: Icons.block_outlined,
      title: 'Permissão necessária',
      message:
          'Para usar este recurso, precisamos de acesso a $permission.\nConceda a permissão nas configurações.',
      actionLabel: 'Conceder Permissão',
      onAction: onRequestPermission,
      type: TravelEmptyStateType.warning,
    );
  }

  /// Estado de recurso Premium
  factory TravelEmptyState.premiumRequired({
    VoidCallback? onUpgrade,
  }) {
    return TravelEmptyState(
      icon: Icons.workspace_premium,
      title: 'Recurso Premium',
      message:
          'Este recurso está disponível apenas para usuários Premium.\nFaça upgrade e desbloqueie todos os recursos!',
      actionLabel: 'Fazer Upgrade',
      onAction: onUpgrade,
      type: TravelEmptyStateType.premium,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina cor baseada no tipo
    final Color iconColor = _getIconColor();
    final Color? actionColor = _getActionColor();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(TravelSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustração ou ícone
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                width: TravelSpacing.iconXxl * 2,
                height: TravelSpacing.iconXxl * 2,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: TravelSpacing.iconXxl,
                  color: iconColor,
                ),
              ),

            SizedBox(height: TravelSpacing.lg),

            // Título
            Semantics(
              header: true,
              child: Text(
                title,
                style: TravelTextStyles.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: TravelSpacing.sm),

            // Mensagem
            Text(
              message,
              style: TravelTextStyles.bodyMedium(context).copyWith(
                color: TravelColors.stoneGray,
              ),
              textAlign: TextAlign.center,
            ),

            // Botão de ação (se houver)
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: TravelSpacing.xl),
              TravelButton(
                label: actionLabel!,
                onPressed: onAction,
                type: _getButtonType(),
                size: TravelButtonSize.large,
                icon: _getActionIcon(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIconColor() {
    switch (type) {
      case TravelEmptyStateType.neutral:
        return TravelColors.stoneGray;
      case TravelEmptyStateType.action:
        return TravelColors.skyBlue;
      case TravelEmptyStateType.error:
        return TravelColors.error;
      case TravelEmptyStateType.warning:
        return TravelColors.warning;
      case TravelEmptyStateType.premium:
        return TravelColors.premium;
    }
  }

  Color? _getActionColor() {
    switch (type) {
      case TravelEmptyStateType.neutral:
      case TravelEmptyStateType.action:
        return TravelColors.skyBlue;
      case TravelEmptyStateType.error:
        return TravelColors.error;
      case TravelEmptyStateType.warning:
        return TravelColors.warning;
      case TravelEmptyStateType.premium:
        return TravelColors.premium;
    }
  }

  TravelButtonType _getButtonType() {
    switch (type) {
      case TravelEmptyStateType.neutral:
      case TravelEmptyStateType.action:
        return TravelButtonType.primary;
      case TravelEmptyStateType.error:
        return TravelButtonType.danger;
      case TravelEmptyStateType.warning:
        return TravelButtonType.secondary;
      case TravelEmptyStateType.premium:
        return TravelButtonType.premium;
    }
  }

  IconData? _getActionIcon() {
    switch (type) {
      case TravelEmptyStateType.action:
        return Icons.add;
      case TravelEmptyStateType.error:
        return Icons.refresh;
      case TravelEmptyStateType.warning:
        return Icons.settings;
      case TravelEmptyStateType.premium:
        return Icons.workspace_premium;
      case TravelEmptyStateType.neutral:
        return null;
    }
  }
}

/// Tipos de estado vazio
enum TravelEmptyStateType {
  /// Neutro - Sem ação específica
  neutral,

  /// Ação - Incentiva criação/adição
  action,

  /// Erro - Algo deu errado
  error,

  /// Aviso - Atenção necessária
  warning,

  /// Premium - Recurso bloqueado
  premium,
}

// Made with Bob
