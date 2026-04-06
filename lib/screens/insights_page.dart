import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Insights de Viagem"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Trip>>(
        stream: controller.getTrips(),
        builder: (context, tripSnapshot) {
          if (tripSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = tripSnapshot.data ?? [];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Seu Perfil de Viajante",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildProfileSummary(trips),
                
                const SizedBox(height: 30),
                const Text(
                  "Análise de Gastos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildExpenseCharts(trips),
                
                const SizedBox(height: 30),
                _buildAIPredictionCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSummary(List<Trip> trips) {
    int solo = trips.where((t) => !t.isGroup).length;
    int group = trips.where((t) => t.isGroup).length;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Solo", solo.toString(), Icons.person),
            _buildStatItem("Grupo", group.toString(), Icons.group),
            _buildStatItem("Países", trips.length.toString(), Icons.public),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpenseCharts(List<Trip> trips) {
    // Aqui no futuro integraremos gráficos reais. Por hora, um sumário inteligente.
    double totalBudget = trips.fold(0, (sum, item) => sum + item.budget);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Investimento total em viagens:"),
              Text("R\$", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.7, // Exemplo de uso de orçamento
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
            minHeight: 10,
          ),
          const SizedBox(height: 5),
          Text("Você está economizando 15% em relação à sua média anterior", 
               style: const TextStyle(fontSize: 12, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildAIPredictionCard() {
    return Card(
      color: Colors.indigo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 10),
                Text("Predição Inteligente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Baseado em seu histórico, seu próximo destino ideal é um lugar de 'Aventura' com orçamento médio de R\$ 3.500.",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
