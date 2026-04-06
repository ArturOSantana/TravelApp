import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';
import 'create_expense_page.dart';

class ExpensesPage extends StatelessWidget {
  final String tripId;
  const ExpensesPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle Financeiro"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateExpensePage(tripId: tripId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<Expense>>(
        stream: controller.getExpenses(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];
          double total = 0;
          for (var e in expenses) {
            total += e.value;
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text("Total Gasto", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text(
                      "R\$ ${total.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                  ? const Center(child: Text("Nenhum gasto registrado."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.remove, color: Colors.white),
                            ),
                            title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(expense.category),
                            trailing: Text(
                              "R\$ ${expense.value.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
