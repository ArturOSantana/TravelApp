import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'itinerary_page.dart';
import 'expenses_page.dart';
import 'journal_page.dart';

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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com informações da viagem
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.flight_takeoff, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.destination,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Objetivo: ${trip.objective}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            "Orçamento: R\$ ${trip.budget.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "Gerenciamento",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildOptionCard(
                context, 
                Icons.calendar_month, 
                "Roteiro Inteligente", 
                "Organize suas atividades diárias",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.account_balance_wallet, 
                "Controle Financeiro", 
                "Gerencie gastos solo ou em grupo",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExpensesPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.auto_stories, 
                "Diário de Viagem", 
                "Registre memórias e fotos",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => JournalPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.gpp_good, 
                "Segurança e SOS", 
                "Compartilhamento e botão de pânico",
                () {} // Próximo passo
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
