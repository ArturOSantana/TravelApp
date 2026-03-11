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

        child: Column(

          children: [

            const SizedBox(height: 20),

            const Text(
              "Painel da Viagem",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Roteiro"),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Gastos"),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Diário"),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Segurança"),
                onPressed: () {},
              ),
            ),

          ],
        ),
      ),
    );
  }
}