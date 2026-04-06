import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import 'create_expense_page.dart';

class ExpensesPage extends StatefulWidget {
  final String tripId;
  const ExpensesPage({super.key, required this.tripId});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle Financeiro"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Histórico", icon: Icon(Icons.history)),
            Tab(text: "Divisão (Grupo)", icon: Icon(Icons.group)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateExpensePage(tripId: widget.tripId),
            ),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildSplitTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];
        double total = 0;
        for (var e in expenses) total += e.value;

        return Column(
          children: [
            _buildTotalHeader(total),
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
    );
  }

  Widget _buildSplitTab() {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = expenseSnapshot.data ?? [];
        double total = 0;
        for (var e in expenses) total += e.value;

        // Precisamos buscar os IDs dos membros da viagem para saber quem são os amigos reais
        return FutureBuilder<List<UserModel>>(
          future: _getRealMembers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final members = userSnapshot.data ?? [];
            if (members.isEmpty) return const Center(child: Text("Nenhum membro no grupo."));

            double perPerson = total / members.length;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Divisão Real do Grupo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Total dividido por ${members.length} participantes:", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _buildDebtCard(member.name, perPerson, _getMemberColor(index));
                      },
                    ),
                  ),
                  const Card(
                    color: Colors.amberAccent,
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Icon(Icons.people_outline),
                          SizedBox(width: 10),
                          Expanded(child: Text("Esta divisão considera apenas os amigos que entraram na viagem usando seu código.")),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<UserModel>> _getRealMembers() async {
    // Primeiro pegamos o documento da viagem para ter a lista de UIDs dos membros
    final tripDoc = await _controller.getTrips().first; // Simplificado: pega a lista atual
    // Como getTrips() retorna um Stream, vamos buscar a viagem específica
    final allTrips = await _controller.getTrips().first;
    final currentTrip = allTrips.firstWhere((t) => t.id == widget.tripId);
    
    return await _controller.getTripMembers(currentTrip.members);
  }

  Color _getMemberColor(int index) {
    List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    return colors[index % colors.length];
  }

  Widget _buildTotalHeader(double total) {
    return Container(
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
          const Text("Total Gasto na Viagem", style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(
            "R\$ ${total.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(String name, double amount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.person, color: Colors.white)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Custo individual"),
        trailing: Text("R\$ ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
