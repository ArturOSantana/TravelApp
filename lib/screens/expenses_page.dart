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
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final trip = Trip.fromFirestore(snapshot.data!);
        final groupMemberIds = <String>{
          if (trip.ownerId.trim().isNotEmpty) trip.ownerId.trim(),
          ...trip.members
              .where((id) => id.trim().isNotEmpty)
              .map((id) => id.trim()),
        };
        // Considera grupo real apenas se tiver 2 ou mais pessoas
        final hasRealGroup = trip.isGroup && groupMemberIds.length >= 2;
        final tabCount = hasRealGroup ? 2 : 1;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Finanças"),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.currency_exchange),
                  onSelected: _updateExchangeRate,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'USD',
                      child: Text("Converter de Dólar (USD)"),
                    ),
                    const PopupMenuItem(
                      value: 'EUR',
                      child: Text("Converter de Euro (EUR)"),
                    ),
                    const PopupMenuItem(
                      value: 'BRL',
                      child: Text("Voltar para Real (BRL)"),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(text: "Histórico", icon: Icon(Icons.list_alt)),
                  if (hasRealGroup)
                    const Tab(
                      text: "Divisão",
                      icon: Icon(Icons.pie_chart_outline),
                    ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Colors.green[800],
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text(
                "Novo Gasto",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateExpensePage(tripId: widget.tripId),
                  ),
                );
              },
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allExpenses = snapshot.data ?? [];
        final expenses = allExpenses
            .where((e) => e.category != 'payment')
            .toList();

        double totalSpent = expenses.fold(
          0,
          (acc, e) => acc + (e.value * _exchangeRate),
        );
        double remaining = trip.budget - totalSpent;
        double progress = trip.budget > 0
            ? (totalSpent / trip.budget).clamp(0.0, 1.0)
            : 0;

        return Column(
          children: [
            if (_isConverting)
              const LinearProgressIndicator(color: Colors.orange),
            _buildBudgetHeader(totalSpent, trip.budget, remaining, progress),
            Expanded(
              child: allExpenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allExpenses.length,
                      itemBuilder: (context, index) =>
                          _buildExpenseCard(allExpenses[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetHeader(
    double spent,
    double budget,
    double remaining,
    double progress,
  ) {
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
          if (_selectedCurrency != 'BRL')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Câmbio: 1 $_selectedCurrency = R\$ ${_exchangeRate.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Gasto (BRL)",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "R\$ ${spent.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOver ? "Excedido" : "Disponível",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "R\$ ${remaining.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isOver ? Colors.orangeAccent : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final bool isPayment = expense.category == 'payment';
    final double displayValue = expense.value * _exchangeRate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPayment
              ? Colors.blue.withValues(alpha: 0.2)
              : _getCategoryColor(expense.category).withValues(alpha: 0.2),
          child: Icon(
            isPayment ? Icons.handshake : _getCategoryIcon(expense.category),
            color: isPayment
                ? Colors.blue
                : _getCategoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${isPayment ? 'Acerto' : _translateCategory(expense.category)} • ${DateFormat('dd/MM').format(expense.date)}\n${_buildExpenseSubtitle(expense)}",
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "R\$ ${displayValue.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPayment ? Colors.green : Colors.redAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteExpense(expense);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Remover gasto'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() =>
      const Center(child: Text("Nenhum gasto registrado."));

  Widget _buildSplitTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allExpenses = snapshot.data ?? [];
        final groupMemberIds = <String>{
          if (trip.ownerId.trim().isNotEmpty) trip.ownerId.trim(),
          ...trip.members
              .where((id) => id.trim().isNotEmpty)
              .map((id) => id.trim()),
        }.toList();
        final isSoloTrip = !trip.isGroup && groupMemberIds.length <= 1;

        if (isSoloTrip) {
          return _buildSoloFinanceSummary(allExpenses);
        }

        return FutureBuilder<List<UserModel>>(
          future: _controller.getTripMembers(groupMemberIds),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Usa os dados retornados pelo controller (que já tem lógica de fallback)
            final members = userSnapshot.data ?? [];

            final Map<String, double> balances = {
              for (final member in members) member.uid: 0.0,
            };

            for (final e in allExpenses) {
              final double val = e.value * _exchangeRate;

              if (e.category == 'payment') {
                balances[e.payerId] = (balances[e.payerId] ?? 0) + val;

                if (e.splits.isNotEmpty) {
                  final recipientId = e.splits.keys.first;
                  balances[recipientId] = (balances[recipientId] ?? 0) - val;
                }

                continue;
              }

              balances[e.payerId] = (balances[e.payerId] ?? 0) + val;

              if (e.splits.isNotEmpty) {
                final splitTotal = e.splits.values.fold<double>(
                  0.0,
                  (acc, part) => acc + part,
                );

                e.splits.forEach((userId, splitValue) {
                  final proportionalValue = splitTotal > 0
                      ? val * (splitValue / splitTotal)
                      : 0.0;
                  balances[userId] =
                      (balances[userId] ?? 0) - proportionalValue;
                });
              } else {
                final share = val / members.length;
                for (final m in members) {
                  balances[m.uid] = (balances[m.uid] ?? 0) - share;
                }
              }
            }

            final nonZeroBalances = members
                .where((member) => (balances[member.uid] ?? 0.0).abs() > 0.009)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Balanço do Grupo",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  allExpenses.isEmpty
                      ? 'Ainda não existem gastos registrados para calcular a divisão.'
                      : 'Veja abaixo quem deve receber e quem precisa acertar os gastos.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                if (allExpenses.isEmpty)
                  _buildSplitEmptyState()
                else if (nonZeroBalances.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No momento, todos estão com as contas equilibradas.',
                      ),
                    ),
                  )
                else
                  ...nonZeroBalances.map((member) {
                    final balance = balances[member.uid] ?? 0.0;
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
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(isMe ? "Você" : member.name),
        subtitle: Text(
          balance >= 0
              ? "A receber: R\$ ${balance.toStringAsFixed(2)}"
              : "Deve pagar: R\$ ${balance.abs().toStringAsFixed(2)}",
          style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red),
        ),
        trailing: (!isMe && balance < 0)
            ? ElevatedButton(
                onPressed: () => _shareDebt(member.name, balance.abs(), dest),
                child: const Text("Cobrar"),
              )
            : null,
      ),
    );
  }

  Widget _buildSoloFinanceSummary(List<Expense> allExpenses) {
    final expenses = allExpenses.where((e) => e.category != 'payment').toList();
    final total = expenses.fold<double>(
      0.0,
      (acc, e) => acc + (e.value * _exchangeRate),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Resumo Pessoal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Como esta é uma viagem solo, não há divisão com outras pessoas.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu total de gastos',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          _buildSplitEmptyState()
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Todos os gastos desta viagem pertencem somente a você.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplitEmptyState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Nenhum gasto registrado ainda.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Adicione um gasto no histórico para visualizar o resumo financeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _shareDebt(String name, double amount, String destination) {
    final String text =
        "Olá $name! Na nossa viagem para $destination, sua parte nos gastos até agora é de R\$ ${amount.toStringAsFixed(2)}. Podemos acertar?";
    SharePlus.instance.share(ShareParams(text: text));
  }

  String _buildExpenseSubtitle(Expense expense) {
    if (expense.category == 'payment') {
      return 'Pagamento/acerto entre participantes';
    }

    switch (expense.splitType) {
      case SplitType.equal:
        return 'Dividido igualmente';
      case SplitType.exact:
        return 'Dividido por valor exato';
      case SplitType.percentage:
        return 'Dividido por porcentagem';
      case SplitType.shares:
        return 'Dividido por cotas';
    }
  }

  void _confirmDeleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover gasto'),
        content: Text('Deseja realmente remover "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await _controller.deleteExpense(expense.id);
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Gasto removido com sucesso.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'alimentação':
        return Icons.restaurant;
      case 'transport':
      case 'transporte':
        return Icons.directions_car;
      case 'lodging':
      case 'hospedagem':
        return Icons.hotel;
      default:
        return Icons.payments;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'alimentação':
        return Colors.orange;
      case 'transport':
      case 'transporte':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Alimentação';
      case 'transport':
        return 'Transporte';
      default:
        return category;
    }
  }
}
