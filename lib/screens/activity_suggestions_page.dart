import 'package:flutter/material.dart';
import '../services/geoapify_service.dart';

/// Tela de Sugestões de Atividades para o Roteiro
/// Ao clicar em uma sugestão, preenche apenas nome e localização
/// Usuário precisa completar os outros campos obrigatórios
class ActivitySuggestionsPage extends StatefulWidget {
  final String tripId;
  final String destination;
  final double? lat;
  final double? lon;

  const ActivitySuggestionsPage({
    super.key,
    required this.tripId,
    required this.destination,
    this.lat,
    this.lon,
  });

  @override
  State<ActivitySuggestionsPage> createState() =>
      _ActivitySuggestionsPageState();
}

class _ActivitySuggestionsPageState extends State<ActivitySuggestionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _entertainment = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    if (widget.lat == null || widget.lon == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadAttractions(),
        _loadRestaurants(),
        _loadEntertainment(),
      ]);
    } catch (e) {
      print('Erro ao carregar sugestões: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAttractions() async {
    final attractions = await GeoapifyService.searchPlaces(
      lat: widget.lat!,
      lon: widget.lon!,
      categories: 'tourism.attraction,tourism.sights,heritage',
      radius: 5000,
      limit: 30,
    );
    setState(() => _attractions = attractions);
  }

  Future<void> _loadRestaurants() async {
    final restaurants = await GeoapifyService.searchPlaces(
      lat: widget.lat!,
      lon: widget.lon!,
      categories: 'catering.restaurant,catering.cafe,catering.fast_food',
      radius: 5000,
      limit: 30,
    );
    setState(() => _restaurants = restaurants);
  }

  Future<void> _loadEntertainment() async {
    final entertainment = await GeoapifyService.searchPlaces(
      lat: widget.lat!,
      lon: widget.lon!,
      categories: 'entertainment,leisure,sport',
      radius: 5000,
      limit: 30,
    );
    setState(() => _entertainment = entertainment);
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    // Retorna os dados para preencher o formulário
    Navigator.pop(context, {
      'name': suggestion['name'] ?? 'Sem nome',
      'location': suggestion['address'] ?? suggestion['name'] ?? '',
      'lat': suggestion['lat'],
      'lon': suggestion['lon'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões de Atividades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.attractions), text: 'Atrações'),
            Tab(icon: Icon(Icons.restaurant), text: 'Restaurantes'),
            Tab(icon: Icon(Icons.celebration), text: 'Entretenimento'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestionsList(_attractions, 'atrações'),
                _buildSuggestionsList(_restaurants, 'restaurantes'),
                _buildSuggestionsList(_entertainment, 'entretenimento'),
              ],
            ),
    );
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma sugestão de $type encontrada',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final distance = item['distance'] ?? 0;
        final distanceKm = (distance / 1000).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getIconForType(type),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              item['name'] ?? 'Sem nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['address'] != null && item['address'].isNotEmpty)
                  Text(
                    item['address'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$distanceKm km de distância',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _selectSuggestion(item),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Usar'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'restaurantes':
        return Icons.restaurant;
      case 'entretenimento':
        return Icons.celebration;
      default:
        return Icons.attractions;
    }
  }
}

// Made with Bob
