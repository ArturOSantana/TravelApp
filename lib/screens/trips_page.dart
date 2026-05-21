import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import '../models/service_model.dart';
import '../theme/travel_colors.dart';
import '../theme/travel_spacing.dart';
import '../theme/travel_text_styles.dart';
import '../widgets/core/travel_widgets.dart';
import 'create_trip_page.dart';
import 'trip_dashboard_page.dart';
import 'community_page.dart';
import '../controllers/trip_controller.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _lastViewedTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLastViewed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastViewedTimestamp = prefs.getInt('last_viewed_post') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.cloudWhite,
      appBar: TravelAppBar.standard(
        title: "Minhas Viagens",
        actions: [
          // Badge de comunidade com notificação
          StreamBuilder<List<ServiceModel>>(
            stream: _controller.getCommunityServices(),
            builder: (context, snapshot) {
              bool hasNewPosts = false;
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final latestPostDate = snapshot.data!.first.updatedAt ??
                    snapshot.data!.first.lastUsed;
                if (latestPostDate.millisecondsSinceEpoch >
                    _lastViewedTimestamp) {
                  hasNewPosts = true;
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.public),
                    tooltip: "Comunidade",
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityPage(),
                        ),
                      );
                      _loadLastViewed();
                    },
                  ),
                  if (hasNewPosts)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: TravelColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TravelColors.cloudWhite,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: "Entrar em Grupo",
            onPressed: () => _showJoinTripDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: TravelColors.skyBlue,
          labelColor: TravelColors.skyBlue,
          unselectedLabelColor: TravelColors.stoneGray,
          tabs: const [
            Tab(text: "Ativas", icon: Icon(Icons.play_circle_outline)),
            Tab(text: "Planejadas", icon: Icon(Icons.calendar_today)),
            Tab(text: "Finalizadas", icon: Icon(Icons.history)),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Criar nova viagem',
        child: FloatingActionButton.extended(
          backgroundColor: TravelColors.skyBlue,
          foregroundColor: TravelColors.cloudWhite,
          icon: const Icon(Icons.add),
          label: const Text("Nova Viagem"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTripPage()),
            );
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList('active'),
          _buildTripList('planned'),
          _buildTripList('completed'),
        ],
      ),
    );
  }

  void _showJoinTripDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TravelSpacing.radiusXl),
        ),
        title: Semantics(
          header: true,
          child: Text(
            "Entrar em um Grupo",
            style: TravelTextStyles.headlineSmall(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cole o código da viagem que seu amigo compartilhou com você:",
              style: TravelTextStyles.bodyMedium(context),
            ),
            SizedBox(height: TravelSpacing.md),
            TravelTextField.standard(
              controller: codeController,
              label: "Código da Viagem",
              hint: "Ex: ID_DA_VIAGEM",
            ),
          ],
        ),
        actions: [
          TravelButton.text(
            label: "Cancelar",
            onPressed: () => Navigator.pop(context),
          ),
          TravelButton.primary(
            label: "Entrar",
            onPressed: () async {
              if (codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Por favor, insira o código da viagem"),
                    backgroundColor: TravelColors.warning,
                  ),
                );
                return;
              }

              try {
                await _controller.joinTrip(codeController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text("✅ Você entrou no grupo com sucesso!"),
                      backgroundColor: TravelColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errorMessage = "Erro ao entrar no grupo";

                  final errorStr = e.toString();
                  if (errorStr.contains('não encontrada') ||
                      errorStr.contains('not-found')) {
                    errorMessage =
                        "❌ Código inválido. Verifique se copiou corretamente.";
                  } else if (errorStr.contains('já é membro')) {
                    errorMessage = "ℹ️ Você já faz parte deste grupo.";
                  } else if (errorStr.contains('limite')) {
                    errorMessage =
                        "⚠️ Grupo atingiu o limite de membros (3 no plano gratuito).";
                  } else if (errorStr.contains('permission-denied')) {
                    errorMessage =
                        "🔒 Você não tem permissão para entrar neste grupo.";
                  } else {
                    errorMessage = "❌ $errorStr";
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: TravelColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(String status) {
    return StreamBuilder<List<Trip>>(
      stream: _controller.getTrips(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TravelLoadingIndicator());
        }

        if (snapshot.hasError) {
          return TravelEmptyState.error(
            errorMessage: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final trips = snapshot.data ?? [];

        if (trips.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: EdgeInsets.all(TravelSpacing.md),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return _buildTripCard(trip, status);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    switch (status) {
      case 'active':
        return TravelEmptyState.noTrips(
          onCreateTrip: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripPage()),
          ),
        );
      case 'completed':
        return TravelEmptyState(
          icon: Icons.history_edu,
          title: 'Nenhuma viagem finalizada',
          message:
              'Suas viagens concluídas aparecerão aqui.\nFinalize uma viagem ativa para vê-la no histórico.',
          type: TravelEmptyStateType.neutral,
        );
      default:
        return TravelEmptyState(
          icon: Icons.event_busy,
          title: 'Nenhuma viagem planejada',
          message:
              'Comece a planejar sua próxima aventura!\nCrie uma viagem e organize todos os detalhes.',
          actionLabel: 'Criar Viagem',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripPage()),
          ),
          type: TravelEmptyStateType.action,
        );
    }
  }

  Widget _buildTripCard(Trip trip, String status) {
    return TravelCard.trip(
      margin: EdgeInsets.only(bottom: TravelSpacing.md),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripDashboardPage(trip: trip),
        ),
      ),
      child: Row(
        children: [
          // Imagem/Ícone da viagem
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: TravelColors.skyBlueLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
            ),
            child: trip.photoUrl != null && trip.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(TravelSpacing.radiusMd),
                    child: Image.network(
                      trip.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultTripIcon(),
                    ),
                  )
                : _buildDefaultTripIcon(),
          ),

          SizedBox(width: TravelSpacing.md),

          // Informações da viagem
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: TravelTextStyles.titleMedium(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: TravelSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: TravelColors.stoneGray,
                    ),
                    SizedBox(width: TravelSpacing.xs),
                    Text(
                      "R\$ ${trip.budget.toStringAsFixed(2)}",
                      style: TravelTextStyles.bodySmall(context).copyWith(
                        color: TravelColors.stoneGray,
                      ),
                    ),
                  ],
                ),
                if (trip.members.length > 1) ...[
                  SizedBox(height: TravelSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: TravelColors.stoneGray,
                      ),
                      SizedBox(width: TravelSpacing.xs),
                      Text(
                        "${trip.members.length} membros",
                        style: TravelTextStyles.bodySmall(context).copyWith(
                          color: TravelColors.stoneGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Ações
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == 'planned' && trip.isAdmin(_currentUid))
                IconButton(
                  icon: Icon(
                    Icons.play_arrow,
                    color: TravelColors.success,
                  ),
                  onPressed: () => _updateTripStatus(trip.id, 'active'),
                  tooltip: "Iniciar Viagem",
                ),
              if (status == 'active' && trip.isAdmin(_currentUid))
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: TravelColors.skyBlue,
                  ),
                  onPressed: () => _updateTripStatus(trip.id, 'completed'),
                  tooltip: "Finalizar Viagem",
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: TravelColors.error,
                ),
                onPressed: () => _showDeleteDialog(trip),
                tooltip: "Excluir Viagem",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTripIcon() {
    return Padding(
      padding: EdgeInsets.all(TravelSpacing.sm),
      child: Image.asset(
        'assets/images/icone_aviao.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Future<void> _updateTripStatus(String tripId, String newStatus) async {
    try {
      await _controller.updateTripStatus(tripId, newStatus);
      if (mounted) {
        final message = newStatus == 'active'
            ? 'Viagem iniciada com sucesso!'
            : 'Viagem finalizada com sucesso!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: TravelColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar viagem: $e'),
            backgroundColor: TravelColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TravelSpacing.radiusXl),
        ),
        title: Semantics(
          header: true,
          child: Text(
            "Excluir Viagem",
            style: TravelTextStyles.headlineSmall(context),
          ),
        ),
        content: Text(
          "Tem certeza que deseja excluir sua viagem para ${trip.destination}?",
          style: TravelTextStyles.bodyMedium(context),
        ),
        actions: [
          TravelButton.text(
            label: "Cancelar",
            onPressed: () => Navigator.pop(context),
          ),
          TravelButton.danger(
            label: "Excluir",
            onPressed: () {
              _controller.deleteTrip(trip.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// Made with Bob
