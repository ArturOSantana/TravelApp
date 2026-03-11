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

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: const Text("Minhas Viagens"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripsPage(),
                  ),
                );
              },
            ),
          ),

        ],
        ),
      ),
    );
  }
}