import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelSearchPage extends StatefulWidget {
  const HotelSearchPage({super.key});

  @override
  State<HotelSearchPage> createState() => _HotelSearchPageState();
}

class _HotelSearchPageState extends State<HotelSearchPage> {
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final TextEditingController _locationController = TextEditingController();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 10));
  int _guests = 2;
  int _rooms = 1;

  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  final List<Map<String, String>> _suggestions = [
    {'name': 'Orlando, EUA', 'query': 'Orlando'},
    {'name': 'Paris, França', 'query': 'Paris'},
    {'name': 'Tokyo, Japão', 'query': 'Tokyo'},
    {'name': 'Roma, Itália', 'query': 'Rome'},
    {'name': 'Rio de Janeiro', 'query': 'Rio de Janeiro'},
    {'name': 'Cancún, México', 'query': 'Cancun'},
  ];

  void _searchHotels() {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Informe a cidade ou hotel")));
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _results = [
          {
            'name': 'Grand Plaza Hotel',
            'stars': 4,
            'price': 450.0,
            'rating': 8.5,
            'image': Icons.hotel,
            'url': _generateHotelsComUrl(),
          },
          {
            'name': 'Ocean View Resort',
            'stars': 5,
            'price': 890.0,
            'rating': 9.2,
            'image': Icons.beach_access,
            'url': _generateHotelsComUrl(),
          },
          {
            'name': 'Budget Stay Inn',
            'stars': 3,
            'price': 180.0,
            'rating': 7.1,
            'image': Icons.bed,
            'url': _generateHotelsComUrl(),
          },
        ];
        _isSearching = false;
      });
    });
  }

  String _generateHotelsComUrl() {
    final checkInStr = DateFormat('yyyy-MM-dd').format(_checkInDate);
    final checkOutStr = DateFormat('yyyy-MM-dd').format(_checkOutDate);
    return "https://www.hoteis.com/Hotel-Search?destination=${_locationController.text}&startDate=$checkInStr&endDate=$checkOutStr&adults=$_guests";
  }

  Future<void> _openHotelsCom(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _bookHotel(Map<String, dynamic> hotel) async {
    final trip = await _selectValidTrip();
    if (trip == null) return;

    final expense = Expense(
      id: '',
      tripId: trip.id,
      title: "Hotel: ${hotel['name']} em ${_locationController.text}",
      value: hotel['price'],
      category: 'Hospedagem',
      payerId: _currentUid,
      date: DateTime.now(),
    );

    await _controller.addExpense(expense);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Reserva de R\$ ${hotel['price']} atribuída à viagem!"),
        backgroundColor: Colors.indigo,
        action: SnackBarAction(
          label: "VER SITE",
          textColor: Colors.white,
          onPressed: () => _openHotelsCom(hotel['url']),
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
                  child: Text("Crie uma viagem ativa ou planejada primeiro."),
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
        title: const Text("Reserva de Hotéis"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
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
      color: Colors.indigo[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Destino ou Nome do Hotel",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          const Text("Sugestões:",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s['name']!,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.indigo[700],
                    onPressed: () =>
                        setState(() => _locationController.text = s['query']!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateTile("Check-in", _checkInDate,
                    (d) => setState(() => _checkInDate = d)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDateTile("Check-out", _checkOutDate,
                    (d) => setState(() => _checkOutDate = d)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _searchHotels,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white),
              child: const Text("BUSCAR HOTÉIS",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(
      String label, DateTime date, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: false,
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38)),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final h = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(h['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18))),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(Icons.star,
                              size: 14,
                              color: i < h['stars']
                                  ? Colors.amber
                                  : Colors.grey[300])),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(h['rating'].toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                    ),
                    const SizedBox(width: 8),
                    const Text("Muito bom",
                        style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Text("R\$ ${h['price'].toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                  ],
                ),
                const Text("/ noite",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => _openHotelsCom(h['url']),
                            child: const Text("VER SITE"))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bookHotel(h),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[900],
                            foregroundColor: Colors.white),
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
          Icon(Icons.apartment_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Encontre sua hospedagem ideal",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
