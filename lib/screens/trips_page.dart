import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'create_trip_page.dart';
import 'trip_dashboard_page.dart';
import '../controllers/trip_controller.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(title: const Text("Minhas Viagens")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripPage()),
          );
        },
      ),
      body: StreamBuilder<List<Trip>>(
        stream: controller.getTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return const Center(
              child: Text("Nenhuma viagem encontrada. Comece criando uma!"),
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
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.flight, color: Colors.deepPurple),
                  title: Text(
                    trip.destination,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text("Orçamento: R\$ ${trip.budget.toStringAsFixed(2)}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDashboardPage(trip: trip),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
