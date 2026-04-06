import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';
import 'package:intl/intl.dart';

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
            return const Center(child: Text("Nenhuma recomendação pública ainda. Seja o primeiro!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _buildRecommendationCard(context, rec);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, ServiceModel rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Galeria de Fotos (Simulada com a primeira foto ou placeholder)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: rec.photos.isNotEmpty 
              ? Image.network(rec.photos.first, height: 200, width: double.infinity, fit: BoxFit.cover)
              : Container(
                  height: 150, 
                  color: Colors.grey[300], 
                  child: const Icon(Icons.image, size: 50, color: Colors.grey)
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rec.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.white),
                          Text(" ${rec.rating}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text("${rec.category} • ${rec.location}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 15),
                Text(rec.comment, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 15),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
                        const SizedBox(width: 8),
                        Text(rec.userName ?? "Viajante Anônimo", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Lógica para adicionar à biblioteca pessoal
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adicionado à sua biblioteca!")));
                      }, 
                      icon: const Icon(Icons.bookmark_add_outlined), 
                      label: const Text("Salvar")
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
