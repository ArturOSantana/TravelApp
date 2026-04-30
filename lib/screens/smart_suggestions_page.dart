import 'package:flutter/material.dart';
import '../services/geoapify_service.dart';
import '../services/rest_countries_service.dart';
import '../services/openweathermap_service.dart';
import '../services/exchangerate_service.dart';

class SmartSuggestionsPage extends StatefulWidget {
  final String destination;
  final double? lat;
  final double? lon;
  final String? baseCurrency;

  const SmartSuggestionsPage({
    super.key,
    required this.destination,
    this.lat,
    this.lon,
    this.baseCurrency,
  });

  @override
  State<SmartSuggestionsPage> createState() => _SmartSuggestionsPageState();
}

class _SmartSuggestionsPageState extends State<SmartSuggestionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Dados carregados
  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _restaurants = [];
  Map<String, dynamic>? _countryInfo;
  Map<String, dynamic>? _weather;
  List<String> _travelTips = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSuggestions() async {
    setState(() => _isLoading = true);

    try {
      // Carregar em paralelo para ser mais rápido
      await Future.wait([
        _loadAttractions(),
        _loadRestaurants(),
        _loadCountryInfo(),
        _loadWeather(),
      ]);
    } catch (e) {
      print('Erro ao carregar sugestões: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAttractions() async {
    if (widget.lat == null || widget.lon == null) return;

    final attractions = await GeoapifyService.searchPlaces(
      lat: widget.lat!,
      lon: widget.lon!,
      categories: 'tourism.attraction,tourism.sights,entertainment.museum',
      radius: 5000,
      limit: 50,
    );

    setState(() => _attractions = attractions);
  }

  Future<void> _loadRestaurants() async {
    if (widget.lat == null || widget.lon == null) return;

    // Usa GeoapifyService para buscar restaurantes (substitui FoursquareService)
    final restaurants = await GeoapifyService.searchPlaces(
      lat: widget.lat!,
      lon: widget.lon!,
      categories: 'catering.restaurant,catering.cafe,catering.fast_food',
      radius: 3000,
      limit: 20,
    );

    setState(() => _restaurants = restaurants);
  }

  Future<void> _loadCountryInfo() async {
    final country =
        RestCountriesService.extractCountryFromAddress(widget.destination);
    final info = await RestCountriesService.getCountryInfo(country);

    if (info != null) {
      setState(() {
        _countryInfo = info;
        _travelTips = RestCountriesService.getTravelTips(info);
      });
    }
  }

  Future<void> _loadWeather() async {
    try {
      final city =
          RestCountriesService.extractCityFromAddress(widget.destination);
      final weather = await OpenWeatherMapService.getCurrentWeather(city);

      if (mounted) {
        setState(() => _weather = weather);
      }
    } catch (e) {
      print('Erro ao carregar clima: $e');
      if (mounted) {
        setState(() => _weather = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sugestões Inteligentes',
                style: TextStyle(fontSize: 18)),
            Text(
              widget.destination,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.place), text: 'Atrações'),
            Tab(icon: Icon(Icons.restaurant), text: 'Restaurantes'),
            Tab(icon: Icon(Icons.info), text: 'Informações'),
            Tab(icon: Icon(Icons.tips_and_updates), text: 'Dicas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAttractionsTab(),
                _buildRestaurantsTab(),
                _buildCountryInfoTab(),
                _buildTipsTab(),
              ],
            ),
    );
  }

  Widget _buildAttractionsTab() {
    if (_attractions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.place_outlined,
        message: 'Nenhuma atração encontrada',
        subtitle: 'Tente buscar em outra localização',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attractions.length,
      itemBuilder: (context, index) {
        final attraction = _attractions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.place, color: Colors.blue),
            ),
            title: Text(
              attraction['name'] ?? 'Sem nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatKinds(attraction['kinds'] ?? ''),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (attraction['distance'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDistance(attraction['distance']),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addToItinerary(attraction, 'attraction'),
              tooltip: 'Adicionar ao roteiro',
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsTab() {
    if (_restaurants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_outlined,
        message: 'Nenhum restaurante encontrado',
        subtitle: 'Tente buscar em outra localização',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: Colors.orange),
            ),
            title: Text(
              restaurant['name'] ?? 'Sem nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  restaurant['category'] ?? 'Restaurante',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (restaurant['address'] != null &&
                    restaurant['address'].isNotEmpty)
                  Text(
                    restaurant['address'],
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (restaurant['distance'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDistance(restaurant['distance']),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addToItinerary(restaurant, 'restaurant'),
              tooltip: 'Adicionar ao roteiro',
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountryInfoTab() {
    if (_countryInfo == null) {
      return _buildEmptyState(
        icon: Icons.info_outlined,
        message: 'Informações não disponíveis',
        subtitle: 'Não foi possível carregar dados do país',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeira e nome
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _countryInfo!['flagEmoji'] ?? '',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _countryInfo!['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _countryInfo!['capital'] ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clima
          if (_weather != null) ...[
            const Text(
              'Clima Atual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wb_sunny,
                      color: Colors.orange, size: 32),
                ),
                title: Text('${_weather!['temp']}°C'),
                subtitle: Text(_weather!['desc'] ?? ''),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Informações gerais
          const Text(
            'Informações Gerais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoCard(Icons.attach_money, 'Moeda',
              '${_countryInfo!['currencyName']} (${_countryInfo!['currencySymbol']})'),
          _buildInfoCard(
              Icons.language, 'Idioma', _countryInfo!['language'] ?? 'N/A'),
          _buildInfoCard(Icons.access_time, 'Fuso Horário',
              _countryInfo!['timezone'] ?? 'N/A'),
          _buildInfoCard(Icons.public, 'Região',
              '${_countryInfo!['region']} - ${_countryInfo!['subregion']}'),
          _buildInfoCard(Icons.people, 'População',
              _formatPopulation(_countryInfo!['population'])),

          // Conversão de moeda
          if (widget.baseCurrency != null &&
              _countryInfo!['currencyCode'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Conversão de Moeda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCurrencyConverter(),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dicas de Viagem',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_travelTips.isNotEmpty) ...[
            ..._travelTips.map((tip) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.amber),
                    title: Text(tip),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Dicas gerais
          const Text(
            'Dicas Gerais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTipCard(Icons.phone_android, 'Conectividade',
              'Verifique se seu plano de celular funciona no destino ou compre um chip local.'),
          _buildTipCard(Icons.power, 'Tomadas',
              'Leve um adaptador universal para não ficar sem bateria.'),
          _buildTipCard(Icons.credit_card, 'Pagamentos',
              'Avise seu banco sobre a viagem para evitar bloqueios no cartão.'),
          _buildTipCard(Icons.local_hospital, 'Saúde',
              'Contrate um seguro viagem e leve medicamentos básicos.'),
          _buildTipCard(Icons.description, 'Documentos',
              'Faça cópias digitais do passaporte e documentos importantes.'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyConverter() {
    return FutureBuilder<double?>(
      future: ExchangeRateService.convert(
        amount: 100,
        from: widget.baseCurrency!,
        to: _countryInfo!['currencyCode'],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final converted = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '100 ${widget.baseCurrency}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const Icon(Icons.arrow_forward),
                    Text(
                      '${converted.toStringAsFixed(2)} ${_countryInfo!['currencyCode']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatKinds(String kinds) {
    final kindsList = kinds.split(',');
    if (kindsList.isEmpty) return 'Ponto turístico';

    final Map<String, String> translations = {
      'museums': 'Museu',
      'churches': 'Igreja',
      'architecture': 'Arquitetura',
      'natural': 'Natureza',
      'cultural': 'Cultural',
      'historic': 'Histórico',
      'interesting_places': 'Ponto de Interesse',
    };

    return translations[kindsList.first] ?? 'Ponto turístico';
  }

  String _formatDistance(dynamic distance) {
    final dist = distance is int ? distance.toDouble() : distance as double;
    if (dist < 1000) {
      return '${dist.toStringAsFixed(0)}m';
    }
    return '${(dist / 1000).toStringAsFixed(1)}km';
  }

  String _formatPopulation(dynamic pop) {
    final population = pop is int ? pop : 0;
    if (population > 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M habitantes';
    }
    return '${(population / 1000).toStringAsFixed(0)}K habitantes';
  }

  void _addToItinerary(Map<String, dynamic> place, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${place['name']} adicionado ao roteiro!'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => Navigator.pop(context, place),
        ),
      ),
    );
  }
}
