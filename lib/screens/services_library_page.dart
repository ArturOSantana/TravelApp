import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';
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

  final List<String> _categories = ['Todas', 'Hospedagem', 'Restaurante', 'Transporte', 'Outros'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text("Explorar Serviços"),
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
    final bool isLiked = service.likes.contains(_currentUid);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(_getIcon(service.category), color: Colors.indigo),
            title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(service.location),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, size: 20, color: Colors.indigo),
                  onPressed: () => _shareService(service),
                ),
                if (isCommunity)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                    onPressed: () => _importService(service),
                  ),
              ],
            ),
          ),
          if (isCommunity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _controller.toggleLikeService(service.id, service.likes),
                    child: Row(children: [
                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text("${service.likes.length}"),
                    ]),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.bookmark_border, color: Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  Text("${service.savesCount}"),
                  const Spacer(),
                  Text("R\$ ${service.averageCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _shareService(ServiceModel service) {
    final String text = "Ei! Veja essa recomendação de ${service.category} no Travel App:\n\n"
        "*${service.name}*\n"
        " ${service.location}\n"
        " \"${service.comment}\"";
    Share.share(text);
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
