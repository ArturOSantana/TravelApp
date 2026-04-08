import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';
import 'add_recommendation_page.dart';

class ServicesLibraryPage extends StatefulWidget {
  const ServicesLibraryPage({super.key});

  @override
  State<ServicesLibraryPage> createState() => _ServicesLibraryPageState();
}

class _ServicesLibraryPageState extends State<ServicesLibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();
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

  Future<void> _shareService(ServiceModel service, BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final String webUrl = "https://travel-app-etec.web.app/service/${service.id}";
    final String text = "Ei! Veja essa recomendação de ${service.category} no Travel App:\n\n"
        "*${service.name}*\n"
        " ${service.location}\n"
        " \"${service.comment}\"\n\n"
        "Veja mais detalhes aqui: $webUrl";

    await Share.share(
      text, 
      subject: "Confira este lugar!",
      sharePositionOrigin: box != null 
          ? box.localToGlobal(Offset.zero) & box.size 
          : null,
    );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const AddRecommendationPage())
        ),
        child: const Icon(Icons.add_comment),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServiceList(isCommunity: false),
          _buildServiceList(isCommunity: true),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar por nome ou local...",
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
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category, 
                      style: TextStyle(
                        fontSize: 12, 
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: Colors.indigo,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var services = snapshot.data ?? [];

        // Aplicar filtros
        services = services.where((s) {
          final matchesSearch = s.name.toLowerCase().contains(_searchQuery) || 
                               s.location.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == 'Todas' || 
                                 s.category.toLowerCase() == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();

        if (services.isEmpty) {
          return const Center(child: Text("Nenhum serviço encontrado."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: _getCategoryIcon(service.category),
                title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.location),
                    _buildTrustSeal(service.rating),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.indigo, size: 20),
                      onPressed: () => _shareService(service, context),
                    ),
                    if (isCommunity)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                        onPressed: () => _importService(service),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                onTap: () => _showDetails(context, service),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, ServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text("${service.category} • ${service.location}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 20),
              if (service.photos.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: service.photos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(service.photos[index], width: 280, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(service.comment, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.payments, color: Colors.green),
                  const SizedBox(width: 10),
                  Text("Custo Médio: R\$ ${service.averageCost.toStringAsFixed(2)}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustSeal(double rating) {
    String label = rating >= 4.5 ? "Alta Compatibilidade" : (rating >= 3.5 ? "Moderada" : "Pode não ser ideal");
    Color color = rating >= 4.5 ? Colors.green : (rating >= 3.5 ? Colors.orange : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color, width: 0.5)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _importService(ServiceModel service) async {
    try {
      await _controller.importService(service);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${service.name} importado!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  Widget _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hospedagem': return const Icon(Icons.hotel, color: Colors.indigo);
      case 'restaurante': return const Icon(Icons.restaurant, color: Colors.orange);
      case 'transporte': return const Icon(Icons.directions_car, color: Colors.blue);
      default: return const Icon(Icons.bookmark, color: Colors.grey);
    }
  }
}
