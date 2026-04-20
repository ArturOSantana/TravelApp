import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final TripController controller = TripController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController destinationController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String _selectedObjective = 'Descanso';
  String _baseCurrency = 'BRL';
  bool _isNomad = false;
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _objectives = ['Descanso', 'Aventura', 'Trabalho', 'Cultural', 'Gastronômico'];
  final List<String> _currencies = ['BRL', 'USD', 'EUR', 'GBP', 'ARS'];

  final List<String> _popularDestinations = [
    'Orlando, EUA',
    'Paris, França',
    'Tokyo, Japão',
    'Roma, Itália',
    'Rio de Janeiro, Brasil',
    'Londres, Inglaterra',
    'Nova York, EUA',
    'Cancún, México',
  ];

  int get _tripDuration {
    if (_startDate == null || _endDate == null || _isNomad) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  void _showConfirmationDialog() {
    if (!formKey.currentState!.validate()) return;
    
    if (!_isNomad && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Defina as datas da viagem.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.green),
            SizedBox(width: 10),
            Text("Confirmar Viagem"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tudo pronto para sua nova aventura? Confira os detalhes:", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            _buildSummaryRow(Icons.location_on, "Destino", destinationController.text),
            _buildSummaryRow(Icons.calendar_month, "Período", _isNomad ? "Modo Nômade" : "${DateFormat('dd/MM').format(_startDate!)} até ${DateFormat('dd/MM').format(_endDate!)}"),
            _buildSummaryRow(Icons.payments, "Orçamento", "$_baseCurrency ${budgetController.text}"),
            _buildSummaryRow(Icons.flag, "Estilo", _selectedObjective),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Editar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _createTrip();
            },
            child: const Text("Confirmar e Criar"),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart 
        ? (_startDate ?? now) 
        : (_endDate ?? (_startDate ?? now).add(const Duration(days: 1)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStart ? now.subtract(const Duration(days: 30)) : (_startDate ?? now),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _createTrip() async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final newTrip = Trip(
        id: '', 
        ownerId: uid,
        destination: destinationController.text.trim(),
        budget: double.tryParse(budgetController.text) ?? 0.0,
        baseCurrency: _baseCurrency,
        objective: _selectedObjective,
        isNomad: _isNomad,
        isGroup: false,
        members: [uid],
        createdAt: DateTime.now(),
        startDate: _startDate,
        endDate: _isNomad ? null : _endDate,
        photoUrl: null,
      );

      await controller.addTrip(newTrip);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Planejar Viagem")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Para onde você vai?", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  TextFormField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      hintText: "Digite o destino ou escolha abaixo",
                      prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Informe o destino" : null,
                  ),

                  const SizedBox(height: 12),
                  const Text("Sugestões populares:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularDestinations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(_popularDestinations[index]),
                            onPressed: () {
                              setState(() {
                                destinationController.text = _popularDestinations[index];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDateTile(label: "Ida", date: _startDate, icon: Icons.flight_takeoff, onTap: () => _pickDate(context, true))),
                            if (!_isNomad) ...[
                              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                              Expanded(child: _buildDateTile(label: "Volta", date: _endDate, icon: Icons.flight_land, onTap: () => _pickDate(context, false), enabled: _startDate != null)),
                            ],
                          ],
                        ),
                        if (_tripDuration > 0 && !_isNomad)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text("Duração: $_tripDuration dias", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ),
                        const Divider(height: 30),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Modo Nômade"),
                          subtitle: const Text("Sem data de volta definida", style: TextStyle(fontSize: 11)),
                          value: _isNomad,
                          onChanged: (v) => setState(() => _isNomad = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text("Orçamento e Moeda", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _baseCurrency,
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _baseCurrency = v!),
                          decoration: const InputDecoration(labelText: "Moeda Base", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Orçamento Planejado", prefixIcon: Icon(Icons.payments), border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Informe o valor" : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Estilo da Viagem", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedObjective,
                    items: _objectives.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => setState(() => _selectedObjective = v!),
                    decoration: const InputDecoration(labelText: "Objetivo", border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _showConfirmationDialog, // Chama o diálogo de confirmação
                      child: const Text("CRIAR VIAGEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDateTile({required String label, DateTime? date, required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(date == null ? "Selecionar" : DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
