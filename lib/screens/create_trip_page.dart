import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final TripController controller = TripController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController destinationController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String _selectedObjective = 'Descanso';
  bool _isNomad = false;
  bool _isGroup = false;
  bool _isLoading = false;

  final List<String> _objectives = ['Descanso', 'Aventura', 'Trabalho', 'Cultural', 'Gastronômico'];

  void createTrip() async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: Usuário não autenticado!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newTrip = Trip(
        id: '', 
        ownerId: uid,
        destination: destinationController.text,
        budget: double.tryParse(budgetController.text) ?? 0.0,
        objective: _selectedObjective,
        isNomad: _isNomad,
        isGroup: _isGroup,
        members: [uid],
        createdAt: DateTime.now(),
      );

      await controller.addTrip(newTrip);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Viagem criada com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova Viagem")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: "Destino (Cidade ou País)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Digite um destino" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Orçamento Estimado (R\$)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Informe o orçamento" : null,
                  ),
                  const SizedBox(height: 20),
                  const Text("Objetivo da Viagem", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _selectedObjective,
                    items: _objectives.map((obj) => DropdownMenuItem(value: obj, child: Text(obj))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedObjective = val);
                      }
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Modo Nômade (Sem data final)"),
                    subtitle: const Text("Ideal para viagens longas e flexíveis"),
                    value: _isNomad,
                    onChanged: (val) => setState(() => _isNomad = val),
                  ),
                  SwitchListTile(
                    title: const Text("Viagem em Grupo"),
                    subtitle: const Text("Permite convidar amigos para colaborar"),
                    value: _isGroup,
                    onChanged: (val) => setState(() => _isGroup = val),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          createTrip();
                        }
                      },
                      child: const Text("Criar Painel da Viagem", style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
