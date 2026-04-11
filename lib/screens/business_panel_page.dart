import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';

class BusinessPanelPage extends StatefulWidget {
  const BusinessPanelPage({super.key});

  @override
  State<BusinessPanelPage> createState() => _BusinessPanelPageState();
}

class _BusinessPanelPageState extends State<BusinessPanelPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão Business B2B"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Clientes", icon: Icon(Icons.people)),
            Tab(text: "Roteiros", icon: Icon(Icons.map)),
            Tab(text: "Métricas", icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientsTab(),
          _buildRoteirosTab(),
          _buildMetricsTab(),
        ],
      ),
    );
  }

  Widget _buildClientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final clients = snapshot.data!.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(client.name),
                subtitle: Text(client.email),
                trailing: IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () => _showClientDetails(client),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoteirosTab() {
    return StreamBuilder<List<Trip>>(
      stream: _controller.getTrips(),
      builder: (context, snapshot) {
        final trips = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.flight_takeoff, color: Colors.blue),
                title: Text(trip.destination),
                subtitle: Text("Cliente: ${trip.ownerId.substring(0, 5)}..."),
                trailing: const Icon(Icons.edit_note),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Desempenho de Conversão", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildMetricCard("Cliques em Links", "1.240", Colors.blue, 0.7),
          _buildMetricCard("Reservas Efetuadas", "85", Colors.green, 0.45),
          _buildMetricCard("Receita Estimada", "R\$ 12.450", Colors.orange, 0.9),
          const SizedBox(height: 30),
          const Card(
            color: Colors.blueAccent,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Suas recomendações na biblioteca estão com 15% mais engajamento este mês.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  void _showClientDetails(UserModel client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("E-mail: ${client.email}"),
            Text("Telefone: ${client.phone}"),
            const Divider(height: 30),
            const Text("Histórico de Viagens", style: TextStyle(fontWeight: FontWeight.bold)),
            const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text("Viagem para Paris (Concluída)")),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Oferecer Novo Roteiro")),
            )
          ],
        ),
      ),
    );
  }
}
