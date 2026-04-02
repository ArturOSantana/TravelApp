import 'package:flutter/material.dart';
import '../models/trip.dart';

class TripDashboardPage extends StatelessWidget {
  final Trip trip;

  const TripDashboardPage({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trip.destination),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Título da viagem
              Text(
                trip.destination,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Orçamento
              Text(
                "Orçamento: R\$ ${trip.budget}",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // Cards de opções
              _buildOptionCard(Icons.map, "Roteiro"),
              _buildOptionCard(Icons.attach_money, "Gastos"),
              _buildOptionCard(Icons.book, "Diário"),
              _buildOptionCard(Icons.security, "Segurança"),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizável para os cards
  Widget _buildOptionCard(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: ListTile(
          leading: Icon(icon, size: 30),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // aqui você pode navegar depois
          },
        ),
      ),
    );
  }
}
















