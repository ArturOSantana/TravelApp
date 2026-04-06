import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar Comunidade"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: controller.getCommunityServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recommendations = snapshot.data ?? [];

          if (recommendations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("Nenhuma recomendação pública ainda."),
                  Text("Seja o primeiro a compartilhar um lugar!"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _buildRecommendationCard(context, rec, controller);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, ServiceModel rec, TripController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, rec, controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem de Capa
            Stack(
              children: [
                rec.photos.isNotEmpty 
                  ? Image.network(rec.photos.first, height: 220, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 180, 
                      width: double.infinity,
                      color: Colors.grey[200], 
                      child: const Icon(Icons.image, size: 60, color: Colors.grey)
                    ),
                Positioned(
                  top: 15, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rec.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      rec.category.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(rec.location, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rec.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14, 
                            backgroundColor: Colors.deepPurple[100],
                            child: const Icon(Icons.person, size: 18, color: Colors.deepPurple)
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Recomendado por:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(rec.userName ?? "Viajante", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _saveToFavorites(context, rec, controller),
                        icon: const Icon(Icons.bookmark_add, size: 18), 
                        label: const Text("SALVAR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveToFavorites(BuildContext context, ServiceModel rec, TripController controller) async {
    try {
      await controller.importService(rec);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${rec.name} foi adicionado aos seus favoritos!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDetails(BuildContext context, ServiceModel rec, TripController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 50, height: 5,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text("${rec.category} • ${rec.location}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 25),
                    
                    if (rec.photos.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: rec.photos.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(rec.photos[index], width: 300, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 30),
                    const Text("A experiência de quem recomendou:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(rec.comment, style: const TextStyle(fontSize: 16, height: 1.6)),
                    
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Icon(Icons.payments, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          "Custo Estimado: R\$ ${rec.averageCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20, 
                          backgroundColor: Colors.deepPurple[50],
                          child: const Icon(Icons.person, color: Colors.deepPurple),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Postado por", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(rec.userName ?? "Viajante", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveToFavorites(context, rec, controller);
                        },
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text("SALVAR NA MINHA BIBLIOTECA", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
