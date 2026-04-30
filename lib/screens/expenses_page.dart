import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';
import '../services/exchangerate_service.dart';
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

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
    final bool isDifferentCurrency = expense.currency != 'BRL';

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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd/MM/yyyy').format(expense.date)),
              if (isDifferentCurrency) ...[
                const SizedBox(height: 4),
                Text(
                  'Original: ${ExchangeRateService.formatCurrency(expense.originalValue, expense.currency)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (expense.exchangeRateUsed != 1.0)
                  Text(
                    'Taxa: 1 ${expense.currency} = ${expense.exchangeRateUsed.toStringAsFixed(4)} BRL',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "R\$ ${expense.value.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  if (isDifferentCurrency && expense.conversionDate != null)
                    Text(
                      DateFormat('dd/MM').format(expense.conversionDate!),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
              if (isDifferentCurrency)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'reconvert') {
                      _showReconvertDialog(expense);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reconvert',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 8),
                          Text('Reconverter'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitTab(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses =
            snapshot.data!.where((e) => e.category != 'payment').toList();

        if (expenses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum gasto registrado ainda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione gastos para ver a divisão entre os membros',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        // Calcular balanço de cada membro
        final balances = _calculateBalances(expenses, trip);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBalanceSummaryCard(balances, trip),
            const SizedBox(height: 20),
            _buildSettlementSuggestions(balances, trip),
            const SizedBox(height: 20),
            _buildDetailedBreakdown(expenses, trip),
          ],
        );
      },
    );
  }

  Map<String, double> _calculateBalances(List<Expense> expenses, Trip trip) {
    final balances = <String, double>{};

    // Inicializar balanços para todos os membros
    final allMembers = <String>{
      if (trip.ownerId.isNotEmpty) trip.ownerId,
      ...trip.members,
    };

    for (final memberId in allMembers) {
      balances[memberId] = 0.0;
    }

    // Calcular balanço de cada membro
    for (final expense in expenses) {
      // Quem pagou recebe crédito
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0.0) + expense.value;

      // Cada pessoa deve sua parte
      expense.splits.forEach((memberId, amount) {
        balances[memberId] = (balances[memberId] ?? 0.0) - amount;
      });
    }

    return balances;
  }

  Widget _buildBalanceSummaryCard(Map<String, double> balances, Trip trip) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 10),
                const Text(
                  'Balanço dos Membros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...balances.entries.map((entry) {
              return FutureBuilder<String>(
                future: _getMemberName(entry.key),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Carregando...';
                  final balance = entry.value;
                  final isPositive = balance > 0.01;
                  final isNegative = balance < -0.01;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? Colors.green[50]
                                : isNegative
                                    ? Colors.red[50]
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${balance >= 0 ? '+' : ''}${_currencyFormat.format(balance)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? Colors.green[700]
                                  : isNegative
                                      ? Colors.red[700]
                                      : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementSuggestions(Map<String, double> balances, Trip trip) {
    final settlements = _calculateSettlements(balances);

    if (settlements.isEmpty) {
      return Card(
        color: Colors.green[50],
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Todas as contas estão acertadas! 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.blue[700]),
                const SizedBox(width: 10),
                const Text(
                  'Sugestões de Acerto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Transferências necessárias para acertar as contas:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const Divider(height: 24),
            ...settlements.map((settlement) {
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  _getMemberName(settlement['from']!),
                  _getMemberName(settlement['to']!),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final fromName = snapshot.data![0];
                  final toName = snapshot.data![1];
                  final amount = settlement['amount']!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: fromName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: ' deve pagar '),
                                TextSpan(
                                  text: _currencyFormat
                                      .format(double.parse(amount)),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const TextSpan(text: ' para '),
                                TextSpan(
                                  text: toName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.blue[700]),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _calculateSettlements(
      Map<String, double> balances) {
    final settlements = <Map<String, String>>[];
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    // Separar devedores e credores
    balances.forEach((memberId, balance) {
      if (balance < -0.01) {
        debtors[memberId] = -balance;
      } else if (balance > 0.01) {
        creditors[memberId] = balance;
      }
    });

    // Calcular transferências mínimas
    final debtorsList = debtors.entries.toList();
    final creditorsList = creditors.entries.toList();

    int i = 0, j = 0;
    while (i < debtorsList.length && j < creditorsList.length) {
      final debtor = debtorsList[i];
      final creditor = creditorsList[j];

      final amount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      settlements.add({
        'from': debtor.key,
        'to': creditor.key,
        'amount': amount.toStringAsFixed(2),
      });

      debtorsList[i] = MapEntry(debtor.key, debtor.value - amount);
      creditorsList[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtorsList[i].value < 0.01) i++;
      if (creditorsList[j].value < 0.01) j++;
    }

    return settlements;
  }

  Widget _buildDetailedBreakdown(List<Expense> expenses, Trip trip) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.orange[700]),
                const SizedBox(width: 10),
                const Text(
                  'Detalhamento dos Gastos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...expenses.map((expense) {
              return FutureBuilder<String>(
                future: _getMemberName(expense.payerId),
                builder: (context, snapshot) {
                  final payerName = snapshot.data ?? 'Carregando...';

                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      expense.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Pago por $payerName • ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: Text(
                      _currencyFormat.format(expense.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Divisão (${_getSplitTypeLabel(expense.splitType)}):',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...expense.splits.entries.map((split) {
                              return FutureBuilder<String>(
                                future: _getMemberName(split.key),
                                builder: (context, nameSnapshot) {
                                  final memberName =
                                      nameSnapshot.data ?? 'Carregando...';
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('  • $memberName'),
                                        Text(
                                          _currencyFormat.format(split.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<String> _getMemberName(String memberId) async {
    if (memberId == _currentUid) return 'Eu';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final name = data?['name'] ?? data?['email']?.split('@')[0];
        return name ?? 'Membro';
      }
    } catch (e) {
      // Silently fail
    }

    return 'Membro';
  }

  Future<void> _showReconvertDialog(Expense expense) async {
    try {
      final newRate = await ExchangeRateService.getExchangeRate(
        from: expense.currency,
        to: 'BRL',
      );

      if (newRate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível obter a taxa de câmbio atual'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final newValue = expense.originalValue * newRate;
      final difference = newValue - expense.value;
      final percentChange = ((difference / expense.value) * 100).abs();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reconverter Despesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Valor original:',
                ExchangeRateService.formatCurrency(
                  expense.originalValue,
                  expense.currency,
                ),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                'Taxa antiga:',
                '1 ${expense.currency} = ${expense.exchangeRateUsed.toStringAsFixed(4)} BRL',
              ),
              _buildInfoRow(
                'Valor convertido:',
                _currencyFormat.format(expense.value),
              ),
              if (expense.conversionDate != null)
                _buildInfoRow(
                  'Data conversão:',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(expense.conversionDate!),
                ),
              const Divider(height: 24),
              _buildInfoRow(
                'Taxa atual:',
                '1 ${expense.currency} = ${newRate.toStringAsFixed(4)} BRL',
                highlight: true,
              ),
              _buildInfoRow(
                'Novo valor:',
                _currencyFormat.format(newValue),
                highlight: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difference >= 0 ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      difference >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: difference >= 0 ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diferença: ${_currencyFormat.format(difference.abs())} (${percentChange.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: difference >= 0
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _controller.updateExpense(expense.id, {
                    'value': newValue,
                    'exchangeRateUsed': newRate,
                    'conversionDate': DateTime.now(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Despesa reconvertida com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao reconverter: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reconverter'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue[700] : Colors.black87,
              fontSize: highlight ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getSplitTypeLabel(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Igualmente';
      case SplitType.exact:
        return 'Valor exato';
      case SplitType.percentage:
        return 'Porcentagem';
      case SplitType.shares:
        return 'Por cotas';
    }
  }
}
