import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/currency_service.dart';

class CreateExpensePage extends StatefulWidget {
  final String tripId;
  const CreateExpensePage({super.key, required this.tripId});

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  final _controller = TripController();
  final _authController = AuthController();
  final _auth = FirebaseAuth.instance;

  final titleController = TextEditingController();
  final valueController = TextEditingController();
  
  String _selectedCategory = 'Alimentação';
  String _selectedCurrency = 'BRL';
  SplitType _selectedSplitType = SplitType.equal;
  
  Trip? _trip;
  List<UserModel> _members = [];
  String? _payerId;
  Map<String, double> _customSplits = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _categories = ['Alimentação', 'Transporte', 'Hospedagem', 'Lazer', 'Saúde', 'Compras', 'Outros'];
  final List<String> _currencies = ['BRL', 'USD', 'EUR', 'GBP', 'ARS'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
    if (tripDoc.exists) {
      _trip = Trip.fromFirestore(tripDoc);
      _selectedCurrency = _trip!.baseCurrency;
      _payerId = _auth.currentUser?.uid;
      
      _members = await _controller.getTripMembers(_trip!.members);
      for (var m in _members) {
        _customSplits[m.uid] = 0.0;
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _saveExpense() async {
    if (titleController.text.isEmpty || valueController.text.isEmpty || _trip == null || _payerId == null) return;

    setState(() => _isSaving = true);

    double originalVal = double.tryParse(valueController.text) ?? 0.0;
    double finalVal = originalVal;

    if (_selectedCurrency != _trip!.baseCurrency) {
      double rate = await CurrencyService.getExchangeRate(_selectedCurrency, _trip!.baseCurrency);
      finalVal = originalVal * rate;
    }

    // Lógica de Split
    Map<String, double> finalSplits = {};
    if (_selectedSplitType == SplitType.equal) {
      double perPerson = originalVal / _members.length;
      for (var m in _members) finalSplits[m.uid] = perPerson;
    } else {
      finalSplits = Map.from(_customSplits);
    }

    final expense = Expense(
      id: '',
      tripId: widget.tripId,
      title: titleController.text,
      value: finalVal,
      originalValue: originalVal,
      currency: _selectedCurrency,
      category: _selectedCategory,
      payerId: _payerId!,
      date: DateTime.now(),
      splitType: _selectedSplitType,
      splits: finalSplits,
    );

    await _controller.addExpense(expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Gasto (Splitwise Style)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickInfo(),
            const SizedBox(height: 20),
            
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Descrição", prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(labelText: "Moeda", border: OutlineInputBorder()),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quanto?", prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 25),
            const Text("Quem pagou?", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildPayerSelector(),
            
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Como dividir?", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<SplitType>(
                  value: _selectedSplitType,
                  items: SplitType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _selectedSplitType = v!),
                ),
              ],
            ),
            _buildSplitEditor(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isSaving ? null : _saveExpense,
                child: _isSaving ? const CircularProgressIndicator() : const Text("REGISTRAR GASTO"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text("Moeda da viagem: ${_trip?.baseCurrency}. Conversão automática ativa.", style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPayerSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final m = _members[index];
          final isSelected = _payerId == m.uid;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(m.uid == _auth.currentUser?.uid ? "Eu" : m.name),
              selected: isSelected,
              onSelected: (v) => setState(() => _payerId = m.uid),
              selectedColor: Colors.green[700],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitEditor() {
    if (_selectedSplitType == SplitType.equal) {
      double total = double.tryParse(valueController.text) ?? 0.0;
      double share = total / _members.length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text("Todos pagam R\$ ${share.toStringAsFixed(2)} igualmente."),
        ),
      );
    }

    return Column(
      children: _members.map((m) {
        return ListTile(
          title: Text(m.name),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Valor"),
              onChanged: (v) => _customSplits[m.uid] = double.tryParse(v) ?? 0.0,
            ),
          ),
        );
      }).toList(),
    );
  }
}
