import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final TextEditingController _originController =
      TextEditingController(text: 'SAO');
  final TextEditingController _destController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedClass = 'economy';
  int _passengers = 1;

  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  final List<Map<String, String>> _classes = [
    {'id': 'economy', 'label': 'Econômica'},
    {'id': 'premiumeconomy', 'label': 'Econômica Premium'},
    {'id': 'business', 'label': 'Executiva'},
    {'id': 'first', 'label': 'Primeira Classe'},
  ];

  // Sugestões de destinos populares para preenchimento rápido
  final List<Map<String, String>> _suggestions = [
    {'name': 'Orlando', 'code': 'MCO'},
    {'name': 'Paris', 'code': 'CDG'},
    {'name': 'Tokyo', 'code': 'HND'},
    {'name': 'Nova York', 'code': 'JFK'},
    {'name': 'Londres', 'code': 'LHR'},
    {'name': 'Roma', 'code': 'FCO'},
    {'name': 'Buenos Aires', 'code': 'EZE'},
    {'name': 'Rio de Janeiro', 'code': 'GIG'},
  ];

  void _searchFlights() {
    if (_destController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Informe o destino")));
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
    });

    // Simulando integração com Skyscanner API
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _results = [
          {
            'company': 'LATAM via Skyscanner',
            'logo': Icons.flight_takeoff,
            'price': _selectedClass == 'first' ? 8500.0 : 450.0,
            'duration': '1h 15m',
            'time': '08:30 - 09:45',
            'url': _generateSkyscannerUrl(),
          },
          {
            'company': 'GOL via Skyscanner',
            'logo': Icons.flight_takeoff,
            'price': _selectedClass == 'first' ? 7200.0 : 380.0,
            'duration': '1h 10m',
            'time': '10:15 - 11:25',
            'url': _generateSkyscannerUrl(),
          },
          {
            'company': 'Azul via Skyscanner',
            'logo': Icons.flight_takeoff,
            'price': _selectedClass == 'first' ? 9100.0 : 520.0,
            'duration': '1h 20m',
            'time': '14:00 - 15:20',
            'url': _generateSkyscannerUrl(),
          },
        ];
        _isSearching = false;
      });
    });
  }

  String _generateSkyscannerUrl() {
    final dateStr = DateFormat('yyMMdd').format(_selectedDate);
    return "https://www.skyscanner.com.br/transporte/voos/${_originController.text}/${_destController.text}/$dateStr/?adults=$_passengers&cabinclass=$_selectedClass";
  }

  Future<void> _openSkyscanner(String url) async {
    final uri = Uri.parse(url);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Aberto com sucesso
    }
  }

  void _bookFlight(Map<String, dynamic> flight) async {
    final trip = await _selectValidTrip();
    if (trip == null) return;

    final expense = Expense(
      id: '',
      tripId: trip.id,
      title:
          "Passagem: ${flight['company']} (${_originController.text} -> ${_destController.text})",
      value: flight['price'],
      category: 'Transporte',
      payerId: _currentUid,
      date: DateTime.now(),
    );

    await _controller.addExpense(expense);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "R\$ ${flight['price']} atribuído à viagem para ${trip.destination}!"),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: "VER SITE",
          textColor: Colors.white,
          onPressed: () => _openSkyscanner(flight['url']),
        ),
      ));
    }
  }

  Future<Trip?> _selectValidTrip() async {
    return await showDialog<Trip>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vincular a qual viagem?"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Trip>>(
            stream: _controller.getTrips(),
            builder: (context, snapshot) {
              final allTrips = snapshot.data ?? [];
              final validTrips = allTrips
                  .where((t) => t.status == 'active' || t.status == 'planned')
                  .toList();

              if (validTrips.isEmpty) {
                return const Center(
                  child: Text("Crie uma viagem ativa ou planejada primeiro.",
                      textAlign: TextAlign.center),
                );
              }

              return ListView.builder(
                itemCount: validTrips.length,
                itemBuilder: (context, i) {
                  final t = validTrips[i];
                  return ListTile(
                    leading: Icon(
                      t.status == 'active'
                          ? Icons.play_circle
                          : Icons.calendar_today,
                      color:
                          t.status == 'active' ? Colors.green : Colors.orange,
                    ),
                    title: Text(t.destination),
                    subtitle: Text(
                        t.status == 'active' ? "Viagem Ativa" : "Planejada"),
                    onTap: () => Navigator.pop(context, t),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Busca de Vôos"),
      ),
      body: Column(
        children: [
          _buildSearchForm(),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue[800],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Origem (IATA)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.flight_takeoff, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _destController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Destino (IATA)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.flight_land, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de sugestões de destinos
          const Text("Sugestões:",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.blue[700],
                    label: Text(suggestion['name']!,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                    onPressed: () {
                      setState(() {
                        _destController.text = suggestion['code']!;
                      });
                      FocusScope.of(context).unfocus(); // Fecha o teclado
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Data",
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: false,
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedClass,
                  dropdownColor: Colors.blue[900],
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 1, color: Colors.white38),
                  items: _classes
                      .map((c) => DropdownMenuItem(
                          value: c['id'], child: Text(c['label']!)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedClass = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _searchFlights,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
              child: const Text("BUSCAR NO SKYSCANNER",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final f = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(f['company'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(f['time'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(f['duration'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Text("R\$ ${f['price'].toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openSkyscanner(f['url']),
                        child: const Text("VER SITE"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bookFlight(f),
                        child: const Text("ATRIBUIR VALOR"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.airplane_ticket_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Busque os melhores preços via Skyscanner",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
