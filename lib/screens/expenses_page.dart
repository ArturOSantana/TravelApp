import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/currency_service.dart';
import 'create_expense_page.dart';
import 'reports_page.dart';

class ExpensesPage extends StatefulWidget {
  final String tripId;
  const ExpensesPage({super.key, required this.tripId});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  double _exchangeRate = 1.0;
  String _selectedCurrency = 'BRL';
  bool _isConverting = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  Future<void> _updateExchangeRate(String from) async {
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
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final trip = Trip.fromFirestore(snapshot.data!);
        final groupMemberIds = <String>{
          if (trip.ownerId.isNotEmpty) trip.ownerId,
          ...trip.members
        }.toList();
        final hasRealGroup = trip.isGroup && groupMemberIds.length >= 2;

        return DefaultTabController(
          length: hasRealGroup ? 2 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Semantics(header: true, child: const Text("Finanças")),
              actions: [
                IconButton(
                  icon: const Icon(Icons.assessment),
                  tooltip: 'Relatórios e Compartilhamento',
                  onPressed: () async {
                    final expensesList =
                        await _controller.getExpenses(widget.tripId).first;
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportsPage(
                            trip: trip,
                            expenses: expensesList,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: "Histórico", icon: Icon(Icons.list_alt)),
                  if (hasRealGroup)
                    const Tab(
                        text: "Divisão", icon: Icon(Icons.pie_chart_outline)),
                ],
              ),
            ),
            floatingActionButton: Semantics(
              label: "Adicionar novo gasto",
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text("Novo Gasto"),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CreateExpensePage(tripId: widget.tripId))),
              ),
            ),
            body: TabBarView(
              children: [
                _buildHistoryTab(trip),
                if (hasRealGroup) _buildSplitTab(trip),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final expenses =
            snapshot.data!.where((e) => e.category != 'payment').toList();
        double totalSpent =
            expenses.fold(0, (acc, e) => acc + (e.value * _exchangeRate));
        double progress =
            trip.budget > 0 ? (totalSpent / trip.budget).clamp(0.0, 1.0) : 0;

        return Column(
          children: [
            Semantics(
              label:
                  "Resumo financeiro. Total gasto: R\$ ${totalSpent.toStringAsFixed(2)}. Orçamento total: R\$ ${trip.budget.toStringAsFixed(2)}",
              child: _buildBudgetHeader(totalSpent, trip.budget, progress),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) =>
                    _buildExpenseCard(snapshot.data![index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetHeader(double spent, double budget, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Gasto",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${spent.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Disponível",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("R\$ ${(budget - spent).toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 8),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final bool isPayment = expense.category == 'payment';
    return Semantics(
      label:
          "Gasto: ${expense.title}. Valor: R\$ ${expense.value.toStringAsFixed(2)}. Data: ${DateFormat('dd/MM').format(expense.date)}",
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPayment
                ? Colors.blue.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Icon(isPayment ? Icons.handshake : Icons.payments,
                color: isPayment ? Colors.blue : Colors.green),
          ),
          title: Text(expense.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('dd/MM').format(expense.date)),
          trailing: Text("R\$ ${expense.value.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildSplitTab(Trip trip) {
    return const Center(
        child: Text("Cálculo de divisão de gastos entre membros do grupo."));
  }
}
