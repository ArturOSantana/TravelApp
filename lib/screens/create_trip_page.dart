import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../data/trip_data.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {

  final TextEditingController destinationController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  void createTrip() {

    final trip = Trip(
      destination: destinationController.text,
      budget: budgetController.text,
    );

    trips.add(trip);

    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Viagem"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(

          children: [

            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: "Destino",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: "Orçamento",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Criar Viagem"),
                onPressed: createTrip,
              ),
            )

          ],
        ),
      ),
    );
  }
}