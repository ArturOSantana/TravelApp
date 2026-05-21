import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/trip_controller.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../theme/travel_colors.dart';
import '../theme/travel_spacing.dart';
import '../theme/travel_text_styles.dart';
import '../widgets/core/travel_widgets.dart';
import 'trips_page.dart';
import 'insights_page.dart';
import 'community_page.dart';
import 'profile_page.dart';
import 'flight_search_page.dart';
import 'hotel_search_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthController _authController = AuthController();
  final TripController _tripController = TripController();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authController.getUserData();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: TravelColors.cloudWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TravelSpacing.radiusXl),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(TravelSpacing.lg),
          child: Column(
            children: [
              // Handle visual
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: TravelSpacing.md),
                decoration: BoxDecoration(
                  color: TravelColors.stoneGrayLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      "Notificações",
                      style: TravelTextStyles.headlineMedium(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: "Fechar notificações",
                  ),
                ],
              ),
              Divider(color: TravelColors.stoneGrayLight),
              SizedBox(height: TravelSpacing.sm),
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: _tripController.getNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return TravelEmptyState.error(
                        errorMessage: snapshot.error.toString(),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const TravelLoadingIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return TravelEmptyState(
                        icon: Icons.notifications_none,
                        title: 'Nenhuma notificação',
                        message: 'Você não tem notificações no momento.',
                        type: TravelEmptyStateType.neutral,
                      );
                    }

                    final notifications = snapshot.data!;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];

                        IconData icon;
                        Color color;
                        String message;

                        switch (notif.type) {
                          case NotificationType.like:
                            icon = Icons.favorite;
                            color = TravelColors.sunsetOrange;
                            message = "${notif.senderName} curtiu seu post";
                            break;
                          case NotificationType.comment:
                            icon = Icons.comment;
                            color = TravelColors.skyBlue;
                            message =
                                "${notif.senderName} comentou no seu post";
                            break;
                          case NotificationType.safetyAlert:
                            icon = Icons.warning;
                            color = TravelColors.warning;
                            message = "ALERTA DE SEGURANÇA";
                            break;
                        }

                        return Semantics(
                          button: true,
                          label: "Notificação de ${notif.senderName}",
                          child: TravelCard.standard(
                            margin: EdgeInsets.only(bottom: TravelSpacing.sm),
                            onTap: () {
                              _tripController.markNotificationAsRead(notif.id);
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                SizedBox(width: TravelSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message,
                                        style: TravelTextStyles.bodyMedium(
                                          context,
                                        ).copyWith(
                                          fontWeight: notif.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: notif.type ==
                                                  NotificationType.safetyAlert
                                              ? TravelColors.error
                                              : null,
                                        ),
                                      ),
                                      SizedBox(height: TravelSpacing.xs),
                                      if (notif.type ==
                                              NotificationType.safetyAlert &&
                                          notif.commentText != null)
                                        Text(
                                          notif.commentText!,
                                          style: TravelTextStyles.bodySmall(
                                            context,
                                          ).copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        Text(
                                          notif.postName,
                                          style: TravelTextStyles.bodySmall(
                                            context,
                                          ),
                                        ),
                                      SizedBox(height: TravelSpacing.xs),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(notif.createdAt),
                                        style: TravelTextStyles.labelSmall(
                                          context,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = TravelSpacing.isMobile(screenWidth);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: TravelLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: TravelColors.cloudWhite,
      appBar: TravelAppBar.standard(
        title: "Travel Planner",
        actions: [
          // Badge de notificações
          StreamBuilder<List<AppNotification>>(
            stream: _tripController.getNotifications(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              if (snapshot.hasData && snapshot.data != null) {
                unreadCount = snapshot.data!.where((n) => !n.isRead).length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => _showNotifications(context),
                    tooltip: unreadCount > 0
                        ? "Você tem $unreadCount novas notificações"
                        : "Sem novas notificações",
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(TravelSpacing.xs),
                        decoration: BoxDecoration(
                          color: TravelColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TravelTextStyles.labelSmall(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Meu Perfil",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) => _loadUser()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Sair da conta",
            onPressed: () async => await _authController.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? TravelSpacing.md : TravelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação personalizada
            Semantics(
              header: true,
              child: Text(
                "Pronto para a próxima aventura, ${_user?.name.split(' ')[0] ?? 'Viajante'}?",
                style: TravelTextStyles.headlineLarge(context),
              ),
            ),
            SizedBox(height: TravelSpacing.xs),
            Text(
              "Explore, planeje e compartilhe suas experiências",
              style: TravelTextStyles.bodyMedium(context).copyWith(
                color: TravelColors.stoneGray,
              ),
            ),

            SizedBox(height: TravelSpacing.xl),

            // Card principal - Minhas Viagens
            TravelCard.trip(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TripsPage()),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: TravelColors.skyBlueLight.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(TravelSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: 28,
                      color: TravelColors.skyBlue,
                    ),
                  ),
                  SizedBox(width: TravelSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Minhas Viagens",
                          style: TravelTextStyles.titleLarge(context),
                        ),
                        SizedBox(height: TravelSpacing.xs),
                        Text(
                          "Gerencie seus roteiros e destinos",
                          style: TravelTextStyles.bodyMedium(context).copyWith(
                            color: TravelColors.stoneGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: TravelColors.stoneGray,
                  ),
                ],
              ),
            ),

            SizedBox(height: TravelSpacing.md),

            // Cards de ação rápida
            Row(
              children: [
                Expanded(
                  child: TravelCard.standard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlightSearchPage(),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: TravelColors.skyBlueLight.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flight_takeoff_rounded,
                            size: 24,
                            color: TravelColors.skyBlue,
                          ),
                        ),
                        SizedBox(height: TravelSpacing.sm),
                        Text(
                          "Voos",
                          style: TravelTextStyles.titleSmall(context),
                        ),
                        SizedBox(height: TravelSpacing.xs),
                        Text(
                          "Buscar passagens",
                          style: TravelTextStyles.labelSmall(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: TravelSpacing.md),
                Expanded(
                  child: TravelCard.standard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HotelSearchPage(),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                TravelColors.sunsetOrangeLight.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.hotel_rounded,
                            size: 24,
                            color: TravelColors.sunsetOrange,
                          ),
                        ),
                        SizedBox(height: TravelSpacing.sm),
                        Text(
                          "Hotéis",
                          style: TravelTextStyles.titleSmall(context),
                        ),
                        SizedBox(height: TravelSpacing.xs),
                        Text(
                          "Reservar hospedagem",
                          style: TravelTextStyles.labelSmall(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: TravelSpacing.xl),

            // Seção de ferramentas
            Semantics(
              header: true,
              child: Text(
                "Ferramentas",
                style: TravelTextStyles.titleLarge(context),
              ),
            ),

            SizedBox(height: TravelSpacing.md),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: TravelSpacing.md,
              mainAxisSpacing: TravelSpacing.md,
              childAspectRatio: 1.1,
              children: [
                _buildToolCard(
                  context,
                  "Resumo",
                  Icons.analytics_rounded,
                  TravelColors.forestGreen,
                  "Ver estatísticas financeiras",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsightsPage(),
                    ),
                  ),
                ),
                _buildToolCard(
                  context,
                  "Comunidade",
                  Icons.people_alt_rounded,
                  TravelColors.skyBlue,
                  "Ver posts e recomendações da comunidade",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunityPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String semanticLabel,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: TravelCard.standard(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            SizedBox(height: TravelSpacing.sm),
            Text(
              title,
              style: TravelTextStyles.titleSmall(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Made with Bob
