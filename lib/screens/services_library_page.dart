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
    
    // URL da versão web do seu app (substitua pelo seu domínio real após o deploy)
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Meus Favoritos", icon: Icon(Icons.star)),
            Tab(text: "Comunidade", icon: Icon(Icons.public)),
          ],
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

  Widget _buildServiceList({required bool isCommunity}) {
    return StreamBuilder<List<ServiceModel>>(
      stream: isCommunity ? _controller.getCommunityServices() : _controller.getPersonalServices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Erro ao carregar dados: ${snapshot.error}"),
            ),
          );
        }

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
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: _getCategoryIcon(service.category),
                title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.location),
                    const SizedBox(height: 4),
                    _buildTrustSeal(service.rating),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (btnContext) => IconButton(
                        icon: const Icon(Icons.share, color: Colors.indigo, size: 20),
                        onPressed: () => _shareService(service, btnContext),
                      ),
                    ),
                    isCommunity
                      ? IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                          onPressed: () => _importService(service),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
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
      useRootNavigator: true,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Builder(
                    builder: (btnContext) => IconButton(
                      icon: const Icon(Icons.share, color: Colors.indigo),
                      onPressed: () => _shareService(service, btnContext),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                          itemBuilder: (context, index) {
                            final photoUrl = service.photos[index];
                            if (photoUrl.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  photoUrl,
                                  width: 280,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 280, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 25),
                    const Text("Avaliação:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          Icons.star,
                          color: i < service.rating.floor() ? Colors.amber : Colors.grey[300],
                          size: 28,
                        )),
                        const SizedBox(width: 10),
                        Text(service.rating.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    const Text("Dica / Comentário:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(service.comment, style: const TextStyle(fontSize: 16, height: 1.5)),
                    
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        const Icon(Icons.payments, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          "Custo Médio: R\$ ${service.averageCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _importService(ServiceModel service) async {
    try {
      await _controller.importService(service);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${service.name} adicionado aos seus favoritos!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
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
