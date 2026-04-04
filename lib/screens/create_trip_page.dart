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
    //favor verificar dps em, projeto ultiliza dados de exemplo por enquanto,estas loinhas abaixo pedem caixa de texto com dados msm
    
      controller.addTrip(
        Trip(
          destination: destinationController.text,
          budget: budgetController.text,
        ),
      ); 
    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Viagem"),
      ),

     body: Padding(
      
  padding: const EdgeInsets.all(20),
  child: Form(
    
    key: _formKey,
    child: Column(
      children: [
            TextFormField(
  controller: destinationController,
  decoration: const InputDecoration(labelText: "Destino"),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Digite um destino";
    }
    return null;
  },
),

            const SizedBox(height: 20),

            TextFormField(
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
               onPressed: () {
                if (_formKey.currentState!.validate()) {
                  createTrip();
                    }
                          },
              ),
            )

          ],
        ),
      ),
    ),
      );
  }
}