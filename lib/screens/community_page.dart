import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explorar Comunidade", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Filtrar por nome, local ou categoria...",
                prefixIcon: const Icon(Icons.search_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_outlined),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: controller.getCommunityServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecommendations = snapshot.data ?? [];
          final recommendations = allRecommendations.where((rec) {
            final name = rec.name.toLowerCase();
            final loc = rec.location.toLowerCase();
            final cat = rec.category.toLowerCase();
            return name.contains(_searchQuery) || 
                   loc.contains(_searchQuery) || 
                   cat.contains(_searchQuery);
          }).toList();

          if (recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.public_off_outlined : Icons.search_off_outlined, 
                    size: 80, 
                    color: Colors.grey[300]
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty ? "Nenhuma recomendação pública ainda." : "Nenhum resultado encontrado.",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _searchQuery.isEmpty ? "Seja o primeiro a compartilhar um lugar!" : "Tente outro termo de busca.",
                    style: const TextStyle(color: Colors.grey)
                  ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, rec, controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                rec.photos.isNotEmpty 
                  ? Image.network(rec.photos.first, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 180, 
                      width: double.infinity,
                      color: Colors.grey[100], 
                      child: const Icon(Icons.image_outlined, size: 60, color: Colors.grey)
                    ),
                Positioned(
                  top: 15, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_outline, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rec.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(rec.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      Text(
                        rec.category.toUpperCase(),
                        style: const TextStyle(color: Colors.deepPurple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(rec.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rec.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: Colors.grey[100], child: const Icon(Icons.person_outline, size: 14, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(rec.userName ?? "Viajante", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text("R\$ ${rec.averageCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
            content: Text("${rec.name} salvo nos favoritos!"),
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
        height: MediaQuery.of(context).size.height * 0.85,
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
                    Text(rec.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
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
                    const Text("A experiência:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(rec.comment, style: const TextStyle(fontSize: 16, height: 1.6)),
                    
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          "Custo Médio: R\$ ${rec.averageCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveToFavorites(context, rec, controller);
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text("SALVAR NA BIBLIOTECA", style: TextStyle(fontWeight: FontWeight.bold)),
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
