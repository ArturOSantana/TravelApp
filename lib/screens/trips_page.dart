import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import '../models/service_model.dart';
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

  Future<void> _loadLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastViewedTimestamp = prefs.getInt('last_viewed_post') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text(
            "Minhas Viagens",
            style: TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: false,
        actions: [
          // Widget do Planeta com Notificação
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
                            builder: (context) => const CommunityPage()),
                      );
                      _loadLastViewed(); // Atualiza o estado local ao voltar
                    },
                  ),
                  if (hasNewPosts)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
        child: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
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
        title: const Text("Entrar em um Grupo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cole o código de convite que seu amigo compartilhou com você:",
              ),
              const SizedBox(height: 15),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: "Código de Convite",
                  border: OutlineInputBorder(),
                  hintText: "Ex: ABC123",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Por favor, insira o código de convite"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await _controller.joinTripWithCode(codeController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Você entrou no grupo com sucesso!"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
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
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text("Entrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(String status) {
    debugPrint('🖥️ [UI] Construindo lista para status: $status');
    return StreamBuilder<List<Trip>>(
      stream: _controller.getTrips(status: status),
      builder: (context, snapshot) {
        debugPrint(
            '🖥️ [UI] StreamBuilder - ConnectionState: ${snapshot.connectionState}');
        debugPrint('🖥️ [UI] StreamBuilder - HasData: ${snapshot.hasData}');
        debugPrint(
            '🖥️ [UI] StreamBuilder - Data length: ${snapshot.data?.length ?? 0}');
        debugPrint('🖥️ [UI] StreamBuilder - HasError: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('🖥️ [UI] StreamBuilder - Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];
        debugPrint('🖥️ [UI] Viagens recebidas para $status: ${trips.length}');

        if (trips.isEmpty) {
          IconData icon;
          String message;

          switch (status) {
            case 'active':
              icon = Icons.explore_off;
              message = "Nenhuma viagem ativa.";
              break;
            case 'completed':
              icon = Icons.history_edu;
              message = "Nenhum histórico de viagens.";
              break;
            default:
              icon = Icons.event_busy;
              message = "Nenhuma viagem planejada.";
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text(message),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: trip.photoUrl != null && trip.photoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              Image.network(trip.photoUrl!, fit: BoxFit.cover),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/icone_aviao.png', //logo do rafa
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                title: Text(
                  trip.destination,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Orçamento: R\$ ${trip.budget.toStringAsFixed(2)}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'planned' && trip.isAdmin(_currentUid))
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () async {
                          try {
                            await _controller.updateTripStatus(
                              trip.id,
                              'active',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Viagem iniciada com sucesso.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao iniciar viagem: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        tooltip: "Iniciar Viagem",
                      ),
                    if (status == 'active' && trip.isAdmin(_currentUid))
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.blue),
                        onPressed: () async {
                          try {
                            await _controller.updateTripStatus(
                              trip.id,
                              'completed',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Viagem finalizada com sucesso!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao finalizar viagem: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        tooltip: "Finalizar Viagem",
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteDialog(trip),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDashboardPage(trip: trip),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Viagem"),
        content: Text(
          "Tem certeza que deseja excluir sua viagem para ${trip.destination}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              _controller.deleteTrip(trip.id);
              Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
