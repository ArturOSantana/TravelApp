import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import 'create_trip_page.dart';
import 'trip_dashboard_page.dart';
import 'community_page.dart'; // Import da nova tela
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Viagens"),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: "Explorar Comunidade",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: "Entrar em um Grupo",
            onPressed: () => _showJoinTripDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: "Ativas", icon: Icon(Icons.play_circle_outline)),
            Tab(text: "Planejadas", icon: Icon(Icons.calendar_today)),
            Tab(text: "Finalizadas", icon: Icon(Icons.history)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripPage()),
          );
        },
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Cole o código da viagem que seu amigo compartilhou com você:",
            ),
            const SizedBox(height: 15),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Código da Viagem",
                border: OutlineInputBorder(),
                hintText: "Ex: ID_DA_VIAGEM",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                try {
                  await _controller.joinTrip(codeController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Você entrou no grupo com sucesso!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro ao entrar no grupo: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
    return StreamBuilder<List<Trip>>(
      stream: _controller.getTrips(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = snapshot.data ?? [];

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
                leading: Icon(
                  status == 'completed' ? Icons.archive : Icons.flight,
                  color: status == 'completed'
                      ? Colors.grey
                      : Colors.deepPurple,
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
//testando