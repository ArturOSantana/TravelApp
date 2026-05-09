import 'package:flutter/material.dart';
import '../services/geoapify_service.dart';
import '../services/location_service.dart';
import '../controllers/trip_controller.dart';
import '../models/place_rating.dart';
import 'package:geolocator/geolocator.dart';
import 'rate_place_page.dart';
import 'place_reviews_page.dart';

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
  final TripController _controller = TripController();
  bool _isLoading = true;

  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _entertainment = [];

  // Localização atual do usuário
  Position? _userLocation;

  // Cache de estatísticas de lugares
  final Map<String, PlaceStats?> _placeStatsCache = {};

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
      // Tentar obter localização atual do usuário
      _userLocation = await LocationService.getCurrentLocation();

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

    // Recalcular distâncias baseadas na localização do usuário
    if (_userLocation != null) {
      for (var attraction in attractions) {
        final distance = LocationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          attraction['lat'],
          attraction['lon'],
        );
        attraction['distance'] = distance.toInt();
      }
    }

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

    // Recalcular distâncias baseadas na localização do usuário
    if (_userLocation != null) {
      for (var restaurant in restaurants) {
        final distance = LocationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          restaurant['lat'],
          restaurant['lon'],
        );
        restaurant['distance'] = distance.toInt();
      }
    }

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

    if (_userLocation != null) {
      for (var item in entertainment) {
        final distance = LocationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          item['lat'],
          item['lon'],
        );
        item['distance'] = distance.toInt();
      }
    }

    setState(() => _entertainment = entertainment);
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    // Retorna os dados
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
        final placeId = _generatePlaceId(item);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
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
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$distanceKm km de distância',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    // Avaliações
                    FutureBuilder<PlaceStats?>(
                      future: _getPlaceStats(placeId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final stats = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                _buildStarRating(stats.averageRating),
                                const SizedBox(width: 4),
                                Text(
                                  stats.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${stats.totalRatings})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
              // Botões de ação
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_rate, size: 18),
                        label: const Text('Avaliar'),
                        onPressed: () => _openRatePage(item, type),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.reviews, size: 18),
                        label: const Text('Reviews'),
                        onPressed: () => _openReviewsPage(item),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectSuggestion(item),
                        child: const Text('Usar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Gera um ID único para o lugar baseado em suas coordenadas
  String _generatePlaceId(Map<String, dynamic> item) {
    final lat = item['lat']?.toString() ?? '';
    final lon = item['lon']?.toString() ?? '';
    return 'place_${lat}_$lon'.replaceAll('.', '_');
  }

  // Busca estatísticas do lugar (com cache)
  Future<PlaceStats?> _getPlaceStats(String placeId) async {
    if (_placeStatsCache.containsKey(placeId)) {
      return _placeStatsCache[placeId];
    }

    try {
      final stats = await _controller.getPlaceStats(placeId);
      _placeStatsCache[placeId] = stats;
      return stats;
    } catch (e) {
      return null;
    }
  }

  // Abre a página de avaliação
  void _openRatePage(Map<String, dynamic> item, String type) async {
    final placeId = _generatePlaceId(item);
    final category = _getCategoryFromType(type);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatePlacePage(
          placeId: placeId,
          placeName: item['name'] ?? 'Sem nome',
          placeAddress: item['address'] ?? '',
          placeLat: item['lat']?.toDouble(),
          placeLon: item['lon']?.toDouble(),
          placeCategory: category,
          tripId: widget.tripId,
        ),
      ),
    );

    // Atualiza o cache se uma avaliação foi adicionada
    if (result == true) {
      setState(() {
        _placeStatsCache.remove(placeId);
      });
    }
  }

  // Abre a página de reviews
  void _openReviewsPage(Map<String, dynamic> item) {
    final placeId = _generatePlaceId(item);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceReviewsPage(
          placeId: placeId,
          placeName: item['name'] ?? 'Sem nome',
          placeAddress: item['address'] ?? '',
        ),
      ),
    );
  }

  // Converte tipo de lista para categoria
  String _getCategoryFromType(String type) {
    switch (type) {
      case 'restaurantes':
        return 'restaurant';
      case 'entretenimento':
        return 'entertainment';
      default:
        return 'attraction';
    }
  }

  // Widget de estrelas
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 14, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 14, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: 14, color: Colors.grey[400]);
        }
      }),
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
