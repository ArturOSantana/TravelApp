import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/gauge_chart_widget.dart';
import '../widgets/charts/waterfall_chart_widget.dart';
import '../widgets/charts/heatmap_widget.dart';
import 'premium_upgrade_page.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final TripController _controller = TripController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  Trip? _selectedTrip;
  bool _showGeneral = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!);
        setState(() => _isPremium = userData.isPremium);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Resumo & Análise",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (!_showGeneral)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => setState(() => _showGeneral = true),
              tooltip: "Ver Geral",
            ),
        ],
      ),
      body: StreamBuilder<List<Trip>>(
        stream: _controller.getTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(
              child: Text("Nenhuma viagem encontrada para análise."),
            );
          }

          return Column(
            children: [
              if (!_isPremium) _buildPremiumBanner(),
              _buildTripSelector(trips),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _showGeneral
                      ? _buildGeneralInsights(trips)
                      : _buildIndividualInsights(_selectedTrip!),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium,
              color: AppColors.textOnPrimary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Desbloqueie Resumos Avançados",
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Análises, relatórios PDF e muito mais!",
                  style: TextStyle(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumUpgradePage(),
                ),
              );
              if (result == true) {
                _checkPremiumStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Upgrade"),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSelector(List<Trip> trips) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text("Visão Geral"),
            selected: _showGeneral,
            onSelected: (selected) {
              if (selected) setState(() => _showGeneral = true);
            },
            // a visao geral
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          ...trips.map((trip) {
            final isSelected = !_showGeneral && _selectedTrip?.id == trip.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  trip.destination,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showGeneral = false;
                      _selectedTrip = trip;
                    });
                  }
                },
                //os demais
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGeneralInsights(List<Trip> trips) {
    final completed = trips.where((t) => t.status == 'completed').toList();
    double totalInvested = trips.fold(0, (sum, t) => sum + t.budget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Resumo da Jornada"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Viagens",
                trips.length.toString(),
                Icons.map,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Concluídas",
                completed.length.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("Investimento Total"),
        const SizedBox(height: 12),
        _buildBudgetSummaryCard(totalInvested, trips.length),
        const SizedBox(height: 24),
        _buildSectionTitle("Estilo de Viagem"),
        _buildTravelStyleChart(trips),
      ],
    );
  }

  Widget _buildIndividualInsights(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(trip.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                const Text('Nenhuma despesa registrada ainda'),
              ],
            ),
          );
        }

        // Calcula estatísticas completas
        final stats = AnalyticsService.calculateTripStatistics(
          trip: trip,
          expenses: expenses,
        );

        final dailySpending = AnalyticsService.groupByDay(expenses);

        int daysElapsed = trip.startDate != null
            ? DateTime.now().difference(trip.startDate!).inDays + 1
            : 1;
        int totalDays = trip.startDate != null && trip.endDate != null
            ? trip.endDate!.difference(trip.startDate!).inDays + 1
            : daysElapsed;
        double dailyBudget = totalDays > 0 ? trip.budget / totalDays : 0;

        return DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.destination,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tabs de navegação
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard), text: 'Resumo'),
                    Tab(icon: Icon(Icons.show_chart), text: 'Gráficos'),
                    Tab(icon: Icon(Icons.analytics), text: 'Análise'),
                    Tab(icon: Icon(Icons.calendar_view_month), text: 'Calor'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Conteúdo das tabs
              SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: TabBarView(
                  children: [
                    // Tab 1: Resumo
                    _buildSummaryTab(trip, stats, expenses),

                    // Tab 2: Gráficos (Premium)
                    _isPremium
                        ? _buildChartsTab(
                            trip, stats, dailySpending, dailyBudget)
                        : _buildPremiumLockedContent('Gráficos Avançados'),

                    // Tab 3: Análise Detalhada (Premium)
                    _isPremium
                        ? _buildAnalysisTab(stats, expenses)
                        : _buildPremiumLockedContent('Análise Detalhada'),

                    // Tab 4: Mapa de Calor (Premium)
                    _isPremium
                        ? _buildHeatmapTab(dailySpending)
                        : _buildPremiumLockedContent('Mapa de Calor'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(
      Trip trip, TripStatistics stats, List<Expense> expenses) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Índice de Eficiência
          _buildEfficiencyCard(stats),
          const SizedBox(height: 16),

          // Recomendações
          if (stats.recommendations.isNotEmpty) ...[
            _buildRecommendationsCard(stats.recommendations),
            const SizedBox(height: 16),
          ],

          // Saúde Financeira
          _buildSectionTitle("Saúde Financeira"),
          const SizedBox(height: 12),
          _buildEnhancedFinancialHealth(trip, stats),
          const SizedBox(height: 24),

          // Estatísticas Detalhadas
          _buildSectionTitle("Estatísticas Detalhadas"),
          const SizedBox(height: 12),
          _buildDetailedStats(stats),
        ],
      ),
    );
  }

  Widget _buildChartsTab(Trip trip, TripStatistics stats,
      Map<DateTime, double> dailySpending, double dailyBudget) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Velocímetro de Orçamento
          GaugeChartWidget(
            value: stats.totalSpent / trip.budget,
            title: 'Uso do Orçamento',
            subtitle:
                '${(stats.totalSpent / trip.budget * 100).toStringAsFixed(1)}% do orçamento utilizado',
          ),
          const SizedBox(height: 24),

          // Gráfico de Linha Temporal
          LineChartWidget(
            data: dailySpending,
            title: 'Evolução de Gastos Diários',
            lineColor: AppColors.primary,
            showMovingAverage: true,
            budgetLine: dailyBudget,
          ),
          const SizedBox(height: 24),

          // Gráfico de Cascata
          WaterfallChartWidget(
            initialBudget: trip.budget,
            categories: stats.categoryBreakdown,
            title: 'Consumo do Orçamento por Categoria',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(TripStatistics stats, List<Expense> expenses) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distribuição de Gastos
          _buildSectionTitle("Distribuição por Categoria"),
          const SizedBox(height: 12),
          _buildCategoryDistribution(expenses),
          const SizedBox(height: 24),

          // Gastos por Dia da Semana
          _buildSectionTitle("Gastos por Dia da Semana"),
          const SizedBox(height: 12),
          _buildWeekdayDistribution(stats.weekdayBreakdown),
          const SizedBox(height: 24),

          // Outliers
          if (stats.outliers.isNotEmpty) ...[
            _buildSectionTitle("Gastos Atípicos"),
            const SizedBox(height: 12),
            _buildOutliersCard(stats.outliers),
            const SizedBox(height: 16),
            Text(
              'Estes gastos estão muito acima ou abaixo da sua média, indicando eventos especiais ou oportunidades de economia.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatmapTab(Map<DateTime, double> dailySpending) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeatmapWidget(
            data: dailySpending,
            title: 'Mapa de Calor - Intensidade de Gastos',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Como interpretar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Cores mais quentes (vermelho) = dias com mais gastos\n'
                  '• Cores mais frias (verde) = dias com menos gastos\n'
                  '• Identifique padrões: fins de semana, eventos especiais\n'
                  '• Use para planejar melhor suas próximas viagens',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(TripStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stats.efficiencyColor.withOpacity(0.1),
            stats.efficiencyColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stats.efficiencyColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Índice de Eficiência',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats.efficiencyStatus,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: stats.efficiencyColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: stats.efficiencyColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${(stats.efficiencyIndex * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: stats.efficiencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: stats.efficiencyIndex > 1 ? 1 : stats.efficiencyIndex,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            color: stats.efficiencyColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  rec,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEnhancedFinancialHealth(Trip trip, TripStatistics stats) {
    bool isOverBudget = stats.totalSpent > trip.budget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleInfo(
                  "Orçamento", _currencyFormat.format(trip.budget)),
              _buildSimpleInfo(
                "Gasto Real",
                _currencyFormat.format(stats.totalSpent),
                color: isOverBudget ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: (stats.totalSpent / trip.budget) > 1
                ? 1
                : (stats.totalSpent / trip.budget),
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: isOverBudget ? AppColors.error : AppColors.success,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget
                    ? "Ultrapassou em ${_currencyFormat.format(stats.totalSpent - trip.budget)}"
                    : "Restante: ${_currencyFormat.format(stats.budgetRemaining)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isOverBudget ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Projeção: ${_currencyFormat.format(stats.projectedTotal)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(TripStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatRow(
              'Média por Dia', _currencyFormat.format(stats.averagePerDay)),
          const Divider(height: 24),
          _buildStatRow('Média por Despesa',
              _currencyFormat.format(stats.averagePerExpense)),
          const Divider(height: 24),
          _buildStatRow('Mediana', _currencyFormat.format(stats.median)),
          const Divider(height: 24),
          _buildStatRow('Desvio Padrão', _currencyFormat.format(stats.stdDev)),
          const Divider(height: 24),
          _buildStatRow(
              'Menor Gasto', _currencyFormat.format(stats.minExpense)),
          const Divider(height: 24),
          _buildStatRow(
              'Maior Gasto', _currencyFormat.format(stats.maxExpense)),
          const Divider(height: 24),
          _buildStatRow(
              'Taxa de Queima/Dia', _currencyFormat.format(stats.burnRate)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayDistribution(Map<String, double> weekdayBreakdown) {
    double maxValue = weekdayBreakdown.values.isEmpty
        ? 1
        : weekdayBreakdown.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: weekdayBreakdown.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: maxValue > 0 ? entry.value / maxValue : 0,
                  color: AppColors.primary,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  minHeight: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  _currencyFormat.format(entry.value),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOutliersCard(List<Expense> outliers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Gastos muito acima ou abaixo da média',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...outliers.map((expense) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        expense.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(expense.value),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExpenseComparisonCard(
    double budget,
    double spent,
    double percent,
    bool isOver,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOver
            ? const Color.fromARGB(255, 232, 11, 44)
            : const Color.fromARGB(255, 2, 5, 2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.secondary,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleInfo("Orçamento", _currencyFormat.format(budget)),
              _buildSimpleInfo(
                "Gasto Real",
                _currencyFormat.format(spent),
                color: isOver ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: isOver ? AppColors.error : AppColors.success,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? "Você ultrapassou o planejado em ${_currencyFormat.format(spent - budget)}"
                : "Você ainda tem ${_currencyFormat.format(budget - spent)} disponíveis",
            style: TextStyle(
              fontSize: 12,
              color: isOver ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<Expense> expenses) {
    Map<String, double> categories = {};
    for (var e in expenses) {
      categories[e.category] = (categories[e.category] ?? 0) + e.value;
    }

    if (categories.isEmpty) return const Text("Sem gastos registrados.");

    double totalSpent = expenses.fold(
      0.0,
      (sum, e) => sum + e.value,
    );

    return Column(
      children: categories.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(entry.key, style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: totalSpent > 0 ? entry.value / totalSpent : 0,
                  color: AppColors.primary,
                  backgroundColor: AppColors.divider,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _currencyFormat.format(entry.value),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSimpleInfo(
            "Total Planejado",
            _currencyFormat.format(total),
          ),
          _buildSimpleInfo(
            "Média/Viagem",
            _currencyFormat.format(count > 0 ? total / count : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelStyleChart(List<Trip> trips) {
    int solo = trips.where((t) => !t.isGroup).length;
    int group = trips.where((t) => t.isGroup).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStyleItem("Solo", solo, Icons.person, AppColors.warning),
          _buildStyleItem("Grupo", group, Icons.group, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildStyleItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildAIPredictionCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppColors.textOnPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                "Análise Inteligente",
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message == "Geral"
                ? "Sua tendência atual indica preferência por destinos urbanos. Recomendamos planejar sua próxima viagem com 3 meses de antecedência para economizar 15%."
                : message,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLockedContent(String featureName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              featureName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Este recurso está disponível apenas para usuários Premium',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumUpgradePage(),
                  ),
                );
                if (result == true) {
                  _checkPremiumStatus();
                }
              },
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Fazer Upgrade para Premium'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Desbloqueie gráficos avançados, análises detalhadas e muito mais!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
