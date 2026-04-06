import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';

class ServicesLibraryPage extends StatefulWidget {
  const ServicesLibraryPage({super.key});

  @override
  State<ServicesLibraryPage> createState() => _ServicesLibraryPageState();
}

class _ServicesLibraryPageState extends State<ServicesLibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar Serviços"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Meus Favoritos", icon: Icon(Icons.star)),
            Tab(text: "Comunidade", icon: Icon(Icons.public)),
          ],
        ),
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

  Widget _buildServiceList({required bool isCommunity}) {
    return StreamBuilder<List<ServiceModel>>(
      stream: isCommunity ? _controller.getCommunityServices() : _controller.getPersonalServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = snapshot.data ?? [];

        if (services.isEmpty) {
          return Center(
            child: Text(isCommunity 
              ? "Nenhuma recomendação da comunidade ainda." 
              : "Você ainda não salvou nenhum serviço."),
          );
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
                    const SizedBox(height: 4),
                    _buildTrustSeal(service.rating), // Caso de Uso 18
                  ],
                ),
                trailing: isCommunity 
                  ? IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                      onPressed: () => _importService(service),
                      tooltip: "Salvar nos meus favoritos",
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }

  // Caso de Uso 18: Selo de Confiança Inteligente
  Widget _buildTrustSeal(double rating) {
    String label;
    Color color;
    if (rating >= 4.5) {
      label = "Alta Compatibilidade";
      color = Colors.green;
    } else if (rating >= 3.5) {
      label = "Compatibilidade Moderada";
      color = Colors.orange;
    } else {
      label = "Pode não ser ideal";
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _importService(ServiceModel service) {
    // Lógica para salvar um serviço da comunidade na lista pessoal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${service.name} adicionado aos seus favoritos!")),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hotel': return const Icon(Icons.hotel, color: Colors.indigo);
      case 'restaurante': return const Icon(Icons.restaurant, color: Colors.orange);
      case 'transporte': return const Icon(Icons.directions_car, color: Colors.blue);
      default: return const Icon(Icons.bookmark, color: Colors.grey);
    }
  }
}
