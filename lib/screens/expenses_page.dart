import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/currency_service.dart';
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
  final AuthController _authController = AuthController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  UserModel? _user;
  double _exchangeRate = 1.0;
  String _selectedCurrency = 'BRL';
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authController.getUserData();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _updateExchangeRate(String from) async {
    if (_user?.role == 'user') return; // Bloqueado para grátis

    setState(() => _isConverting = true);
    final rate = await CurrencyService.getExchangeRate(from, 'BRL');
    if (mounted) {
      setState(() {
        _exchangeRate = rate;
        _selectedCurrency = from;
        _isConverting = false;
      });
    }
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
            title: Text("Finanças"),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            actions: [
              if (_user?.role == 'premium' || _user?.role == 'business')
                PopupMenuButton<String>(
                  icon: const Icon(Icons.currency_exchange),
                  onSelected: _updateExchangeRate,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'USD', child: Text("Converter de Dólar (USD)")),
                    const PopupMenuItem(value: 'EUR', child: Text("Converter de Euro (EUR)")),
                    const PopupMenuItem(value: 'BRL', child: Text("Voltar para Real (BRL)")),
                  ],
                )
            ],
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateExpensePage(tripId: widget.tripId)));
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final allExpenses = snapshot.data ?? [];
        final expenses = allExpenses.where((e) => e.category != 'payment').toList();
        
        double totalSpent = expenses.fold(0, (sum, e) => sum + (e.value * _exchangeRate));
        double remaining = trip.budget - totalSpent;
        double progress = trip.budget > 0 ? (totalSpent / trip.budget).clamp(0.0, 1.0) : 0;

        return Column(
          children: [
            if (_isConverting) const LinearProgressIndicator(color: Colors.orange),
            _buildBudgetHeader(totalSpent, trip.budget, remaining, progress),
            Expanded(
              child: allExpenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allExpenses.length,
                      itemBuilder: (context, index) => _buildExpenseCard(allExpenses[index]),
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
      decoration: BoxDecoration(color: Colors.green[700], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(
        children: [
          if (_selectedCurrency != 'BRL')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text("Câmbio: 1 $_selectedCurrency = R\$ ${_exchangeRate.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Gasto (BRL)", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${spent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isOver ? "Excedido" : "Disponível", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${remaining.abs().toStringAsFixed(2)}", style: TextStyle(color: isOver ? Colors.orangeAccent : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: isOver ? Colors.orangeAccent : Colors.white, minHeight: 8),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    bool isPayment = expense.category == 'payment';
    double displayValue = expense.value * _exchangeRate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPayment ? Colors.blue.withOpacity(0.2) : _getCategoryColor(expense.category).withOpacity(0.2),
          child: Icon(isPayment ? Icons.handshake : _getCategoryIcon(expense.category), color: isPayment ? Colors.blue : _getCategoryColor(expense.category)),
        ),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${isPayment ? 'Acerto' : _translateCategory(expense.category)} • ${DateFormat('dd/MM').format(expense.date)}"),
        trailing: Text(
          "R\$ ${displayValue.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: FontWeight.bold, color: isPayment ? Colors.green : Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("Nenhum gasto registrado."));

  Widget _buildSplitTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        final allExpenses = snapshot.data ?? [];
        return FutureBuilder<List<UserModel>>(
          future: _controller.getTripMembers(trip.members),
          builder: (context, userSnapshot) {
            final members = userSnapshot.data ?? [];
            if (members.isEmpty) return const Center(child: CircularProgressIndicator());

            Map<String, double> balances = {};
            for (var m in members) balances[m.uid] = 0.0;

            for (var e in allExpenses) {
              double val = e.value * _exchangeRate;
              if (e.category == 'payment') {
                balances[e.payerId] = (balances[e.payerId] ?? 0) + val;
                String recipientId = e.splits.keys.first;
                balances[recipientId] = (balances[recipientId] ?? 0) - val;
              } else {
                balances[e.payerId] = (balances[e.payerId] ?? 0) + val;
                double share = val / members.length;
                for (var m in members) balances[m.uid] = (balances[m.uid] ?? 0) - share;
              }
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Balanço do Grupo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...members.map((member) {
                  double balance = balances[member.uid] ?? 0.0;
                  return _buildBalanceCard(member, balance, trip.destination);
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(UserModel member, double balance, String dest) {
    bool isMe = member.uid == _currentUid;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: const Icon(Icons.person)),
        title: Text(isMe ? "Você" : member.name),
        subtitle: Text(balance >= 0 ? "A receber: R\$ ${balance.toStringAsFixed(2)}" : "Deve pagar: R\$ ${balance.abs().toStringAsFixed(2)}",
          style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red)),
        trailing: !isMe ? ElevatedButton(onPressed: () => _shareDebt(member.name, balance.abs(), dest), child: const Text("Cobrar")) : null,
      ),
    );
  }

  void _shareDebt(String name, double amount, String destination) {
    final String text = "Olá $name! Na nossa viagem para $destination, sua parte nos gastos até agora é de R\$ ${amount.toStringAsFixed(2)}. Podemos acertar?";
    Share.share(text);
  }

  // Auxiliares de UI
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'alimentação': return Icons.restaurant;
      case 'transport': case 'transporte': return Icons.directions_car;
      case 'lodging': case 'hospedagem': return Icons.hotel;
      default: return Icons.payments;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'alimentação': return Colors.orange;
      case 'transport': case 'transporte': return Colors.blue;
      default: return Colors.teal;
    }
  }

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food': return 'Alimentação';
      case 'transport': return 'Transporte';
      default: return category;
    }
  }
}
