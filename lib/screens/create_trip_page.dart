import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<List<Map<String, dynamic>>> _searchDestinations(String query) async {
    if (query.length < 3) return [];
    
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&accept-language=pt-BR'),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': item['lat'],
          'lon': item['lon'],
        }).toList();
      }
    } catch (e) {
      debugPrint("Erro na busca: $e");
    }
    return [];
  }

  int get _tripDuration {
    if (_startDate == null || _endDate == null || _isNomad) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
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

  void createTrip() async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    if (!_isNomad && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Defina as datas.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newTrip = Trip(
        id: '', 
        ownerId: uid,
        destination: destinationController.text,
        budget: double.tryParse(budgetController.text) ?? 0.0,
        baseCurrency: _baseCurrency,
        objective: _selectedObjective,
        isNomad: _isNomad,
        isGroup: false,
        members: [uid],
        createdAt: DateTime.now(),
        startDate: _startDate,
        endDate: _isNomad ? null : _endDate,
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
                  
                  SearchAnchor(
                    builder: (BuildContext context, SearchController searchController) {
                      return TextFormField(
                        controller: destinationController,
                        readOnly: true, 
                        onTap: () => searchController.openView(),
                        decoration: const InputDecoration(
                          hintText: "Busque qualquer cidade no mundo...",
                          prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Informe o destino" : null,
                      );
                    },
                    suggestionsBuilder: (BuildContext context, SearchController searchController) async {
                      if (searchController.text.length < 3) return [];
                      
                      final results = await _searchDestinations(searchController.text);

                      return results.map((dest) => ListTile(
                        leading: const Icon(Icons.map_outlined, color: Colors.deepPurple),
                        title: Text(dest['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          setState(() {
                            destinationController.text = dest['display_name'];
                            searchController.text = dest['display_name'];
                          });
                          searchController.closeView(dest['display_name']);
                        },
                      )).toList();
                    },
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
                      onPressed: () {
                        if (formKey.currentState!.validate()) createTrip();
                      },
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
