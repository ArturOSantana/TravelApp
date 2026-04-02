import 'package:flutter/material.dart';
import 'trips_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Planner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        children: [
            //substituir por um header bonito,com card
       Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
        ),
      elevation: 4,
        child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TripsPage(),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.card_travel, size: 40),
          const SizedBox(width: 20),
          const Text(
            "Minhas Viagens",
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    ),
  ),
)

        ],
        ),
      ),
    );
  }
}