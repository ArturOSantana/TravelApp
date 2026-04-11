import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';
import 'add_recommendation_page.dart';

class ServicesLibraryPage extends StatefulWidget {
  final String? tripId;
  const ServicesLibraryPage({super.key, this.tripId});

  @override
  State<ServicesLibraryPage> createState() => _ServicesLibraryPageState();
}

class _ServicesLibraryPageState extends State<ServicesLibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  final List<String> _categories = ['Todas', 'Hospedagem', 'Restaurante', 'Transporte', 'Vôos', 'Outros'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace & Serviços"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(170),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: "Favoritos", icon: Icon(Icons.star)),
                  Tab(text: "Comunidade", icon: Icon(Icons.public)),
                  Tab(text: "Passagens", icon: Icon(Icons.flight)),
                ],
              ),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServiceList(isCommunity: false),
          _buildServiceList(isCommunity: true),
          _buildFlightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRecommendationPage())),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar...",
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: _selectedCategory == cat,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList({required bool isCommunity}) {
    return StreamBuilder<List<ServiceModel>>(
      stream: isCommunity ? _controller.getCommunityServices() : _controller.getPersonalServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final services = (snapshot.data ?? []).where((s) {
          final matchesSearch = s.name.toLowerCase().contains(_searchQuery) || s.location.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == 'Todas' || s.category.toLowerCase() == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) => _buildServiceCard(services[index], isCommunity),
        );
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service, bool isCommunity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(_getIcon(service.category), color: Colors.indigo),
            title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(service.location),
            trailing: Text("R\$ ${service.averageCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCommunity)
                  TextButton.icon(
                    onPressed: () => _importService(service),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text("Salvar"),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleBooking(service),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: Text(service.category == 'Restaurante' ? "Reservar" : "Contratar"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFlightsTab() {
    final List<Map<String, dynamic>> flightOffers = [
      {'company': 'LATAM', 'from': 'SAO', 'to': 'RIO', 'price': 350.0, 'date': '15/10'},
      {'company': 'GOL', 'from': 'SAO', 'to': 'FOR', 'price': 890.0, 'date': '20/10'},
      {'company': 'Azul', 'from': 'RIO', 'to': 'LIS', 'price': 4200.0, 'date': '12/11'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Ofertas de Passagens (Exclusivo)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ...flightOffers.map((offer) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(offer['company'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                      Text(offer['date'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(offer['from'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Icon(Icons.flight_takeoff, color: Colors.grey),
                      Text(offer['to'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("R\$ ${offer['price']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ElevatedButton(
                        onPressed: () => _bookFlight(offer),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        child: const Text("COMPRAR AGORA"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        const Text("Parceiros Oficiais", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _partnerLogo("Skyscanner", "https://skyscanner.com.br"),
            _partnerLogo("Booking", "https://booking.com"),
            _partnerLogo("Decolar", "https://decolar.com"),
          ],
        )
      ],
    );
  }

  Widget _partnerLogo(String name, String url) {
    return ActionChip(
      label: Text(name),
      onPressed: () async => await launchUrl(Uri.parse(url)),
    );
  }

  void _handleBooking(ServiceModel service) async {
    final trip = await _selectTrip();
    if (trip == null) return;

    final expense = Expense(
      id: '',
      tripId: trip.id,
      title: "Reserva: ${service.name}",
      value: service.averageCost,
      category: service.category,
      payerId: _currentUid,
      date: DateTime.now(),
    );

    await _controller.addExpense(expense);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Reserva confirmada em ${trip.destination}! Gasto adicionado."),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _bookFlight(Map<String, dynamic> offer) async {
    final trip = await _selectTrip();
    if (trip == null) return;

    final expense = Expense(
      id: '',
      tripId: trip.id,
      title: "Passagem ${offer['from']} -> ${offer['to']}",
      value: offer['price'],
      category: 'Transporte',
      payerId: _currentUid,
      date: DateTime.now(),
    );

    await _controller.addExpense(expense);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Passagem comprada com sucesso e vinculada à viagem!"),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<Trip?> _selectTrip() async {
    if (widget.tripId != null) {
      final trips = await _controller.getTrips().first;
      return trips.firstWhere((t) => t.id == widget.tripId);
    }

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
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) return const Text("Crie uma viagem primeiro.");
              return ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(trips[i].destination),
                  onTap: () => Navigator.pop(context, trips[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _importService(ServiceModel service) async {
    await _controller.importService(service);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo nos favoritos!")));
  }

  IconData _getIcon(String cat) {
    if (cat == 'Restaurante') return Icons.restaurant;
    if (cat == 'Hospedagem') return Icons.hotel;
    return Icons.star;
  }
}
