import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Insights & Análise",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
        gradient: LinearGradient(
          colors: [Colors.deepPurple[700]!, Colors.deepPurple[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Desbloqueie Insights Avançados",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Análises com IA, relatórios PDF e muito mais!",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
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
            selectedColor: Colors.deepPurple,
            labelStyle: TextStyle(
              color: _showGeneral ? Colors.white : Colors.black,
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
                ), // Usando destination em vez de title
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showGeneral = false;
                      _selectedTrip = trip;
                    });
                  }
                },
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
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
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Concluídas",
                completed.length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("Investimento Total"),
        const SizedBox(height: 12),
        _buildBudgetSummaryCard(totalInvested, trips.length),
        const SizedBox(height: 24),
        _buildSectionTitle("Estilo de Viajante"),
        _buildTravelStyleChart(trips),
      ],
    );
  }

  Widget _buildIndividualInsights(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(trip.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        double spent = expenses.fold(
          0,
          (sum, e) => sum + e.value,
        ); // Usando value em vez de amount
        double percent = trip.budget > 0 ? (spent / trip.budget) : 0;
        bool isOverBudget = spent > trip.budget;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.destination,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ), // Usando destination
            const SizedBox(height: 24),

            _buildSectionTitle("Saúde Financeira"),
            const SizedBox(height: 12),
            _buildExpenseComparisonCard(
              trip.budget,
              spent,
              percent,
              isOverBudget,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("Distribuição de Gastos"),
            _buildCategoryDistribution(expenses),
          ],
        );
      },
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
        color: isOver ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver ? Colors.red[100]! : Colors.green[100]!,
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
                color: isOver ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            backgroundColor: Colors.white,
            color: isOver ? Colors.red : Colors.green,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? "Você ultrapassou o planejado em ${_currencyFormat.format(spent - budget)}"
                : "Você ainda tem ${_currencyFormat.format(budget - spent)} disponíveis",
            style: TextStyle(
              fontSize: 12,
              color: isOver ? Colors.red : Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<Expense> expenses) {
    Map<String, double> categories = {};
    for (var e in expenses) {
      categories[e.category] = (categories[e.category] ?? 0) +
          e.value; // Usando value em vez de amount
    }

    if (categories.isEmpty) return const Text("Sem gastos registrados.");

    double totalSpent = expenses.fold(
      0.0,
      (sum, e) => sum + e.value,
    ); // Usando value

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
                  color: Colors.deepPurple,
                  backgroundColor: Colors.grey[200],
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          _buildStyleItem("Solo", solo, Icons.person, Colors.orange),
          _buildStyleItem("Grupo", group, Icons.group, Colors.indigo),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIPredictionCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[700]!, Colors.deepPurple[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Análise Inteligente",
                style: TextStyle(
                  color: Colors.white,
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
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
