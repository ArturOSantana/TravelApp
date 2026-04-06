import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';

class CreateExpensePage extends StatefulWidget {
  final String tripId;
  const CreateExpensePage({super.key, required this.tripId});

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  final _controller = TripController();
  final _auth = FirebaseAuth.instance;

  final titleController = TextEditingController();
  final valueController = TextEditingController();
  
  String _selectedCategory = 'Alimentação';
  final List<String> _categories = ['Alimentação', 'Transporte', 'Hospedagem', 'Lazer', 'Saúde', 'Outros'];

  void _saveExpense() async {
    if (titleController.text.isEmpty || valueController.text.isEmpty) return;

    final expense = Expense(
      id: '',
      tripId: widget.tripId,
      title: titleController.text,
      value: double.tryParse(valueController.text) ?? 0.0,
      category: _selectedCategory,
      payerId: _auth.currentUser?.uid ?? '',
      date: DateTime.now(),
    );

    await _controller.addExpense(expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Gasto"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Descrição (Ex: Jantar no Restaurante X)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Valor (R\$)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "Categoria",
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveExpense,
                child: const Text("Salvar Gasto", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
