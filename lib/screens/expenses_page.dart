import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../models/trip.dart';
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final trip = Trip.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text("Finanças: ${trip.destination}"),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Histórico", icon: Icon(Icons.list_alt)),
                Tab(text: "Divisão", icon: Icon(Icons.pie_chart_outline)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.green[800],
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text("Novo Gasto", style: TextStyle(color: Colors.white)),
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
              _buildHistoryTab(trip),
              _buildSplitTab(trip),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHistoryTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];
        double totalSpent = expenses.fold(0, (sum, e) => sum + e.value);
        double remaining = trip.budget - totalSpent;
        double progress = trip.budget > 0 ? (totalSpent / trip.budget).clamp(0.0, 1.0) : 0;

        return Column(
          children: [
            _buildBudgetHeader(totalSpent, trip.budget, remaining, progress),
            Expanded(
              child: expenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _buildExpenseCard(expense);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetHeader(double spent, double budget, double remaining, double progress) {
    bool isOver = spent > budget;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Gasto", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${spent.toStringAsFixed(2)}", 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isOver ? "Excedido" : "Disponível", 
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${remaining.abs().toStringAsFixed(2)}", 
                    style: TextStyle(
                      color: isOver ? Colors.orangeAccent : Colors.white, 
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: isOver ? Colors.orangeAccent : Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            "Você utilizou ${(progress * 100).toStringAsFixed(1)}% do orçamento de R\$ ${budget.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category).withOpacity(0.2),
          child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category)),
        ),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${_translateCategory(expense.category)} • ${DateFormat('dd/MM').format(expense.date)}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "R\$ ${expense.value.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
            ),
          ],
        ),
        onLongPress: () => _confirmDelete(expense),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Nenhum gasto ainda.", style: TextStyle(color: Colors.grey, fontSize: 18)),
          const Text("Toque no botão + para começar.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Gasto?"),
        content: Text("Deseja realmente excluir '${expense.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('expenses').doc(expense.id).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = expenseSnapshot.data ?? [];
        double total = expenses.fold(0, (sum, e) => sum + e.value);

        return FutureBuilder<List<UserModel>>(
          future: _controller.getTripMembers(trip.members),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final members = userSnapshot.data ?? [];
            if (members.isEmpty) return const Center(child: Text("Nenhum membro no grupo."));

            double perPerson = total / members.length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Divisão do Grupo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Total da viagem: R\$ ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey)),
                Text("Custo por pessoa: R\$ ${perPerson.toStringAsFixed(2)}", 
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 25),
                ...members.asMap().entries.map((entry) {
                  return _buildDebtCard(entry.value.name, perPerson, _getMemberColor(entry.key), trip.destination);
                }),
                const SizedBox(height: 30),
                Card(
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(child: Text("A divisão é calculada igualmente entre todos os membros confirmados na viagem.")),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Auxiliares de UI
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'alimentação': return Icons.restaurant;
      case 'transport': case 'transporte': return Icons.directions_car;
      case 'lodging': case 'hospedagem': return Icons.hotel;
      case 'leisure': case 'lazer': return Icons.confirmation_number;
      case 'shopping': case 'compras': return Icons.shopping_bag;
      default: return Icons.payments;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'alimentação': return Colors.orange;
      case 'transport': case 'transporte': return Colors.blue;
      case 'lodging': case 'hospedagem': return Colors.purple;
      case 'leisure': case 'lazer': return Colors.green;
      case 'shopping': case 'compras': return Colors.pink;
      default: return Colors.teal;
    }
  }

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food': return 'Alimentação';
      case 'transport': return 'Transporte';
      case 'lodging': return 'Hospedagem';
      case 'leisure': return 'Lazer';
      case 'shopping': return 'Compras';
      default: return category;
    }
  }

  Color _getMemberColor(int index) {
    List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    return colors[index % colors.length];
  }

  Widget _buildDebtCard(String name, double amount, Color color, String destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.person, color: Colors.white)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("R\$ ${amount.toStringAsFixed(2)}", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        trailing: ElevatedButton.icon(
          onPressed: () => _shareDebt(name, amount, destination),
          icon: const Icon(Icons.send, size: 16),
          label: const Text("Cobrar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  void _shareDebt(String name, double amount, String destination) {
    final String text = "Olá $name! Na nossa viagem para $destination, sua parte nos gastos até agora é de R\$ ${amount.toStringAsFixed(2)}. Podemos acertar?";
    Share.share(text);
  }
}
