import 'package:flutter/material.dart';
import 'create_trip_page.dart';
import '../data/trip_data.dart';
import 'trip_dashboard_page.dart';
import '../controllers/trip_controller.dart';



class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  final controller = TripController();
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Viagens"),
      ),

    
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTripPage(),
            ),
          );
        },
      ),

      body: ListView.builder(
        itemCount: controller.getTrips().length,
        itemBuilder: (context, index) {
          final trip = controller.getTrips()[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,

            child: ListTile(
              contentPadding: const EdgeInsets.all(16),

              leading: const Icon(Icons.flight),

              title: Text(
                trip.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              subtitle: Text("Orçamento: R\$ ${trip.budget}"),
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
      ),
    );
  }
}
//verificar se o código do create_trip_page.dart está correto,pois tem um trecho estranho no meio,parece que foi colado errado,verificar também o dashboard_page.dart,pois tem um trecho de código que parece ter sido colado errado no meio do arquivo.
//verificar pq ta estranho aq 30/03