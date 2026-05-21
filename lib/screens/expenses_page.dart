import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';
import '../services/exchangerate_service.dart';
import '../theme/app_colors.dart';
import '../theme/travel_colors.dart';
import '../theme/travel_spacing.dart';
import '../theme/travel_text_styles.dart';
import '../widgets/core/travel_widgets.dart';
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

  final Map<String, String> _memberNamesCache = {};

  NumberFormat _getCurrencyFormat(String currency) {
    final symbols = {
      'BRL': 'R\$',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'ARS': '\$',
    };

    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: symbols[currency] ?? currency,
      decimalDigits: 2,
    );
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
          return Scaffold(
            body: Center(
              child: TravelLoadingIndicator(
                message: 'Carregando finanças...',
              ),
            ),
          );
        }
        final trip = Trip.fromFirestore(snapshot.data!);
        final groupMemberIds = <String>{
          if (trip.ownerId.isNotEmpty) trip.ownerId,
          ...trip.members
        }.toList();
        final hasRealGroup = trip.isGroup && groupMemberIds.length >= 2;

        return DefaultTabController(
          length: hasRealGroup ? 2 : 1,
          child: Scaffold(
            appBar: TravelAppBar.standard(
              title: 'Finanças',
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
                indicatorColor: TravelColors.forestGreen,
                labelColor: TravelColors.forestGreen,
                unselectedLabelColor: TravelColors.stoneGray,
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
                backgroundColor: TravelColors.forestGreen,
                foregroundColor: TravelColors.cloudWhite,
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

        // Filtra pagamentos internos (divisão entre membros)
        final despesas =
            snapshot.data!.where((e) => e.category != 'payment').toList();

        // Calcula total gasto considerando taxa de câmbio
        double totalGasto = despesas.fold(
            0,
            (acumulado, despesa) =>
                acumulado + (despesa.value * _exchangeRate));

        // Progresso do orçamento (0 a 100%)
        // LEMBRAR: Clampar entre 0 e 1 para não estourar a barra
        double progresso =
            trip.budget > 0 ? (totalGasto / trip.budget).clamp(0.0, 1.0) : 0;

        return Column(
          children: [
            Semantics(
              label:
                  "Resumo financeiro. Total gasto: ${_getCurrencyFormat(trip.baseCurrency).format(totalGasto)}. Orçamento total: ${_getCurrencyFormat(trip.baseCurrency).format(trip.budget)}",
              child: _buildBudgetHeader(
                  totalGasto, trip.budget, progresso, trip.baseCurrency),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) =>
                    _buildExpenseCard(snapshot.data![index], trip),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetHeader(
      double gasto, double orcamento, double progresso, String currency) {
    final disponivel = orcamento - gasto;
    final currencyFormat = _getCurrencyFormat(currency);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(TravelSpacing.lg),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TravelColors.forestGreen,
              TravelColors.forestGreen.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                  Text("Total Gasto",
                      style: TravelTextStyles.bodyMedium(context,
                          color: TravelColors.cloudWhite.withOpacity(0.9))),
                  Text(currencyFormat.format(gasto),
                      style: TravelTextStyles.headlineLarge(context,
                          color: TravelColors.cloudWhite)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Disponível",
                      style: TravelTextStyles.bodyMedium(context,
                          color: TravelColors.cloudWhite.withOpacity(0.9))),
                  Text(currencyFormat.format(disponivel),
                      style: TravelTextStyles.headlineMedium(context,
                          color: TravelColors.cloudWhite)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progresso do orçamento
          LinearProgressIndicator(
              value: progresso,
              backgroundColor: TravelColors.cloudWhite.withOpacity(0.3),
              color: TravelColors.cloudWhite,
              minHeight: 8),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, Trip trip) {
    final currencyFormat = _getCurrencyFormat(trip.baseCurrency);
    final bool isPayment = expense.category == 'payment';
    final bool isDifferentCurrency = expense.currency != 'BRL';

    return Semantics(
      label:
          "Gasto: ${expense.title}. Valor: ${currencyFormat.format(expense.value)}. Data: ${DateFormat('dd/MM').format(expense.date)}",
      child: Card(
        key: ValueKey('card_${expense.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPayment
                ? AppColors.info.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            child: Icon(isPayment ? Icons.handshake : Icons.payments,
                color: isPayment ? AppColors.info : AppColors.success),
          ),
          title: Text(expense.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(expense.date),
                style: const TextStyle(inherit: true),
              ),
              if (isDifferentCurrency) ...[
                const SizedBox(height: 4),
                Text(
                  'Original: ${ExchangeRateService.formatCurrency(expense.originalValue, expense.currency)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    inherit: true,
                  ),
                ),
                if (expense.exchangeRateUsed != 1.0)
                  Text(
                    'Taxa: 1 ${expense.currency} = ${expense.exchangeRateUsed.toStringAsFixed(4)} BRL',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                      inherit: true,
                    ),
                  ),
              ],
            ],
          ),
          trailing: SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(expense.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          fontSize: 16,
                          inherit: true,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDifferentCurrency && expense.conversionDate != null)
                        Text(
                          DateFormat('dd/MM').format(expense.conversionDate!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDisabled,
                            inherit: true,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: ValueKey('menu_${expense.id}'),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'reconvert') {
                      _showReconvertDialog(expense, trip);
                    } else if (value == 'edit') {
                      _editExpense(expense);
                    } else if (value == 'delete') {
                      _deleteExpense(expense, trip);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (isDifferentCurrency)
                      const PopupMenuItem(
                        value: 'reconvert',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text('Reconverter'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Apagar',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitTab(Trip trip) {
    final currencyFormat = _getCurrencyFormat(trip.baseCurrency);

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
                children: const [
                  Icon(Icons.receipt_long,
                      size: 64, color: AppColors.textDisabled),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum gasto registrado ainda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione gastos para ver a divisão entre os membros',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          );
        }

        final balances = _calculateBalances(expenses, trip);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBalanceSummaryCard(balances, trip, currencyFormat),
            const SizedBox(height: 20),
            _buildSettlementSuggestions(balances, trip, currencyFormat),
            const SizedBox(height: 20),
            _buildDetailedBreakdown(expenses, trip, currencyFormat),
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

    // Arredondar para 2 casas decimais para evitar problemas de precisão
    final roundedBalances = <String, double>{};
    balances.forEach((memberId, balance) {
      roundedBalances[memberId] = double.parse(balance.toStringAsFixed(2));
    });

    return roundedBalances;
  }

  Widget _buildBalanceSummaryCard(
      Map<String, double> balances, Trip trip, NumberFormat currencyFormat) {
    return TravelCard.elevated(
      child: Padding(
        padding: EdgeInsets.all(TravelSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: TravelColors.forestGreen),
                SizedBox(width: TravelSpacing.sm),
                Text(
                  'Balanço dos Membros',
                  style: TravelTextStyles.titleLarge(context),
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
                                ? TravelColors.forestGreen.withOpacity(0.1)
                                : isNegative
                                    ? TravelColors.sunsetOrange.withOpacity(0.1)
                                    : TravelColors.stoneGray.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${balance >= 0 ? '+' : ''}${currencyFormat.format(balance)}',
                            style: TravelTextStyles.bodyLarge(
                              context,
                              color: isPositive
                                  ? TravelColors.forestGreen
                                  : isNegative
                                      ? TravelColors.sunsetOrange
                                      : TravelColors.stoneGray,
                            ).copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildSettlementSuggestions(
      Map<String, double> balances, Trip trip, NumberFormat currencyFormat) {
    final settlements = _calculateSettlements(balances);

    if (settlements.isEmpty) {
      return Card(
        color: AppColors.successBackground,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 32),
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
              children: const [
                Icon(Icons.swap_horiz, color: AppColors.info),
                SizedBox(width: 10),
                Text(
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                      color: AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.infoLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
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
                                  text: currencyFormat
                                      .format(double.parse(amount)),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
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
                        Icon(Icons.arrow_forward, color: AppColors.info),
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

    // Separar devedores e credores (ignorar valores menores que 1 centavo)
    balances.forEach((memberId, balance) {
      final roundedBalance = double.parse(balance.toStringAsFixed(2));
      if (roundedBalance < -0.01) {
        debtors[memberId] = -roundedBalance;
      } else if (roundedBalance > 0.01) {
        creditors[memberId] = roundedBalance;
      }
    });

    // Se não há devedores ou credores, não há acertos a fazer
    if (debtors.isEmpty || creditors.isEmpty) {
      return settlements;
    }

    // Algoritmo Greedy para minimizar número de transações
    final debtorsList = debtors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final creditorsList = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int i = 0, j = 0;
    int maxIterations = debtorsList.length * creditorsList.length;
    int iterations = 0;

    while (i < debtorsList.length && j < creditorsList.length) {
      // Proteção contra loop infinito
      if (iterations++ > maxIterations) {
        debugPrint(
            '[ExpensesPage] Aviso: loop infinito detectado em _calculateSettlements');
        break;
      }

      final debtorAmount = debtorsList[i].value;
      final creditorAmount = creditorsList[j].value;

      // Calcular valor da transferência (o menor entre dívida e crédito)
      final transferAmount =
          debtorAmount < creditorAmount ? debtorAmount : creditorAmount;

      // Arredondar para 2 casas decimais
      final roundedTransfer = double.parse(transferAmount.toStringAsFixed(2));

      // Só adicionar se valor for significativo (> 1 centavo)
      if (roundedTransfer > 0.01) {
        settlements.add({
          'from': debtorsList[i].key,
          'to': creditorsList[j].key,
          'amount': roundedTransfer.toStringAsFixed(2),
        });
      }

      // Atualizar valores restantes
      final newDebtorValue = debtorAmount - roundedTransfer;
      final newCreditorValue = creditorAmount - roundedTransfer;

      debtorsList[i] = MapEntry(debtorsList[i].key, newDebtorValue);
      creditorsList[j] = MapEntry(creditorsList[j].key, newCreditorValue);

      // Avançar índices quando valor for zerado (< 1 centavo)
      if (newDebtorValue < 0.01) i++;
      if (newCreditorValue < 0.01) j++;
    }

    return settlements;
  }

  Widget _buildDetailedBreakdown(
      List<Expense> expenses, Trip trip, NumberFormat currencyFormat) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.list_alt, color: AppColors.warning),
                SizedBox(width: 10),
                Text(
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
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    trailing: Text(
                      currencyFormat.format(expense.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.surfaceVariant,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Divisão (${_getSplitTypeLabel(expense.splitType)}):',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
                                          currencyFormat.format(split.value),
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

    // Verificar cache primeiro
    if (_memberNamesCache.containsKey(memberId)) {
      return _memberNamesCache[memberId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final name = data?['name'] ?? data?['email']?.split('@')[0] ?? 'Membro';

        // Armazenar no cache
        _memberNamesCache[memberId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('[ExpensesPage] Erro ao buscar nome do membro $memberId: $e');
    }

    // Fallback e cache do fallback
    _memberNamesCache[memberId] = 'Membro';
    return 'Membro';
  }

  Future<void> _showReconvertDialog(Expense expense, Trip trip) async {
    final currencyFormat = _getCurrencyFormat(trip.baseCurrency);

    try {
      final newRate = await ExchangeRateService.getExchangeRate(
        from: expense.currency,
        to: trip.baseCurrency,
      );

      if (newRate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível obter a taxa de câmbio atual'),
              backgroundColor: AppColors.error,
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
                '1 ${expense.currency} = ${expense.exchangeRateUsed.toStringAsFixed(4)} ${trip.baseCurrency}',
              ),
              _buildInfoRow(
                'Valor convertido:',
                currencyFormat.format(expense.value),
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
                '1 ${expense.currency} = ${newRate.toStringAsFixed(4)} ${trip.baseCurrency}',
                highlight: true,
              ),
              _buildInfoRow(
                'Novo valor:',
                currencyFormat.format(newValue),
                highlight: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difference >= 0
                      ? AppColors.errorBackground
                      : AppColors.successBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      difference >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color:
                          difference >= 0 ? AppColors.error : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diferença: ${currencyFormat.format(difference.abs())} (${percentChange.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: difference >= 0
                              ? AppColors.error
                              : AppColors.success,
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
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao reconverter: $e'),
                        backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
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
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppColors.info : AppColors.textPrimary,
              fontSize: highlight ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }

  void _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExpensePage(
          tripId: widget.tripId,
          expenseToEdit: expense,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto atualizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _deleteExpense(Expense expense, Trip trip) async {
    final currencyFormat = _getCurrencyFormat(trip.baseCurrency);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja apagar este gasto?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valor: ${currencyFormat.format(expense.value)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteExpense(expense.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gasto apagado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao apagar gasto: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
