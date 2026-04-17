import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';
import '../services/ai_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final TripController _controller = TripController();
  Trip? _selectedTrip;
  bool _showGeneral = true;
  String? _aiAnalysisText;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Análise de Viagem", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_showGeneral)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => setState(() => _showGeneral = true),
              tooltip: "Ver Geral",
            )
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
            return const Center(child: Text("Nenhuma viagem encontrada para análise."));
          }

          return Column(
            children: [
              _buildTripSelector(trips),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _showGeneral ? _buildGeneralInsights(trips) : _buildIndividualInsights(_selectedTrip!),
                ),
              ),
            ],
          );
        },
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
              if (selected) setState(() {
                _showGeneral = true;
                _aiAnalysisText = null;
              });
            },
            selectedColor: Colors.deepPurple,
            labelStyle: TextStyle(color: _showGeneral ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 8),
          ...trips.map((trip) {
            final isSelected = !_showGeneral && _selectedTrip?.id == trip.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(trip.destination),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showGeneral = false;
                      _selectedTrip = trip;
                      _aiAnalysisText = null;
                    });
                  }
                },
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
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
            Expanded(child: _buildStatCard("Viagens", trips.length.toString(), Icons.map, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Concluídas", completed.length.toString(), Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("Investimento Total"),
        const SizedBox(height: 12),
        _buildBudgetSummaryCard(totalInvested, trips.length),
        const SizedBox(height: 24),
        _buildSectionTitle("Estilo de Viajante"),
        _buildTravelStyleChart(trips),
        const SizedBox(height: 32),
        _buildAIPredictionCard("Geral"),
      ],
    );
  }

  Widget _buildIndividualInsights(Trip trip) {
    return StreamBuilder<List<Expense>>(
      stream: _controller.getExpenses(trip.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        double spent = expenses.fold(0, (sum, e) => sum + e.value);
        double percent = trip.budget > 0 ? (spent / trip.budget) : 0;
        bool isOverBudget = spent > trip.budget;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.destination, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            _buildSectionTitle("Saúde Financeira"),
            const SizedBox(height: 12),
            _buildExpenseComparisonCard(trip.budget, spent, percent, isOverBudget),
            
            const SizedBox(height: 24),
            _buildSectionTitle("Distribuição de Gastos"),
            _buildCategoryDistribution(expenses),
            
            const SizedBox(height: 32),
            _buildAIAnalysisButton(trip, expenses),
            if (_aiAnalysisText != null) ...[
              const SizedBox(height: 15),
              _buildAIResponseCard(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAIAnalysisButton(Trip trip, List<Expense> expenses) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : () async {
          setState(() => _isAnalyzing = true);
          final result = await AIService.getTravelAnalysis(trip: trip, expenses: expenses);
          setState(() {
            _aiAnalysisText = result;
            _isAnalyzing = false;
          });
        },
        icon: _isAnalyzing 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome),
        label: const Text("ANALISAR COM IA", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text("Análise do Gemini", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiAnalysisText!,
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseComparisonCard(double budget, double spent, double percent, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOver ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOver ? Colors.red[100]! : Colors.green[100]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleInfo("Orçamento", "R\$ ${budget.toStringAsFixed(0)}"),
              _buildSimpleInfo("Gasto Real", "R\$ ${spent.toStringAsFixed(0)}", color: isOver ? Colors.red : Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            backgroundColor: Colors.white,
            color: isOver ? Colors.red : Colors.green,
            minHeight: 10,
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
    double totalSpent = expenses.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: categories.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text(entry.key, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: LinearProgressIndicator(
                  value: totalSpent > 0 ? entry.value / totalSpent : 0,
                  color: Colors.deepPurple,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(width: 10),
              Text("R\$ ${entry.value.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSimpleInfo("Total Planejado", "R\$ ${total.toStringAsFixed(0)}"),
          _buildSimpleInfo("Média/Viagem", "R\$ ${(count > 0 ? total / count : 0).toStringAsFixed(0)}"),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
        CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        const SizedBox(height: 4),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIPredictionCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple[700]!, Colors.deepPurple[400]!]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Análise Preditiva", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message == "Geral" ? "Sua tendência atual indica preferência por destinos urbanos. Recomendamos planejar sua próxima viagem com 3 meses de antecedência para economizar 15%." : message,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
