import 'package:flutter/material.dart';
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

class _TripsPageState extends State<TripsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityPage())),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: "Entrar em um Grupo",
            onPressed: () => _showJoinTripDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Ativas", icon: Icon(Icons.play_circle_outline)),
            Tab(text: "Planejadas", icon: Icon(Icons.calendar_today)),
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
            const Text("Cole o código da viagem que seu amigo compartilhou com você:"),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                try {
                  await _controller.joinTrip(codeController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Você entrou no grupo com sucesso!"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erro ao entrar no grupo: $e"), backgroundColor: Colors.red),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status == 'active' ? Icons.explore_off : Icons.event_busy, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text("Nenhuma viagem ${status == 'active' ? 'ativa' : 'planejada'}."),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.flight, color: Colors.deepPurple),
                title: Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Orçamento: R\$ ${trip.budget.toStringAsFixed(2)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'planned')
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () => _controller.updateTripStatus(trip.id, 'active'),
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
                  MaterialPageRoute(builder: (context) => TripDashboardPage(trip: trip)),
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
        content: Text("Tem certeza que deseja excluir sua viagem para ${trip.destination}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
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
