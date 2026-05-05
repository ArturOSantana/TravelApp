  Implementação Final das APIs

 Arquitetura de Integração

 Estrutura de Serviços

```
lib/services/
├── geoapify_service.dart           Sugestões de locais
├── openweathermap_service.dart     Previsão do tempo
├── rest_countries_service.dart     Informações de países
├── exchangerate_service.dart       Conversão de moedas
├── external_apps_service.dart      Maps, Calendar, etc
└── http_client_service.dart        Cliente HTTP base
```

 Cliente HTTP Base

```dart
class HttpClientService {
  static final http.Client _client = http.Client();
  
  static Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: ),
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(timeout);
      
      if (response.statusCode == ) {
        return json.decode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }
}
```

 Implementações Específicas

 Geoapify Service

```dart
class GeoapifyService {
  static const String _baseUrl = 'https://api.geoapify.com/v';
  static const String _apiKey = ApiKeys.geoapify;
  
  Future<List<Place>> getSuggestions({
    required double latitude,
    required double longitude,
    required String category,
    int radius = ,
  }) async {
    final url = '$_baseUrl/places'
        '?categories=$category'
        '&filter=circle:$longitude,$latitude,$radius'
        '&limit='
        '&apiKey=$_apiKey';
    
    final data = await HttpClientService.get(url);
    return (data['features'] as List)
        .map((f) => Place.fromJson(f))
        .toList();
  }
}
```

 OpenWeatherMap Service

```dart
class OpenWeatherMapService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/.';
  static const String _apiKey = ApiKeys.openWeatherMap;
  
  Future<Weather> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final url = '$_baseUrl/weather'
        '?lat=$latitude'
        '&lon=$longitude'
        '&units=metric'
        '&lang=pt_br'
        '&appid=$_apiKey';
    
    final data = await HttpClientService.get(url);
    return Weather.fromJson(data);
  }
  
  Future<List<Forecast>> getDayForecast({
    required double latitude,
    required double longitude,
  }) async {
    final url = '$_baseUrl/forecast'
        '?lat=$latitude'
        '&lon=$longitude'
        '&units=metric'
        '&lang=pt_br'
        '&appid=$_apiKey';
    
    final data = await HttpClientService.get(url);
    return (data['list'] as List)
        .map((f) => Forecast.fromJson(f))
        .toList();
  }
}
```

 Tratamento de Erros

 Strategy Pattern

```dart
abstract class ApiErrorHandler {
  String handleError(Exception e);
}

class NetworkErrorHandler implements ApiErrorHandler {
  @override
  String handleError(Exception e) {
    if (e is SocketException) {
      return 'Sem conexão com a internet';
    }
    if (e is TimeoutException) {
      return 'Tempo de resposta excedido';
    }
    return 'Erro de rede';
  }
}
```

 Cache e Otimização

 Cache Service

```dart
class ApiCacheService {
  static final Map<String, CachedData> _cache = {};
  
  static Future<T?> get<T>(
    String key, {
    required Duration maxAge,
  }) async {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired(maxAge)) {
      return cached.data as T;
    }
    return null;
  }
  
  static Future<void> set(String key, dynamic data) async {
    _cache[key] = CachedData(
      data: data,
      timestamp: DateTime.now(),
    );
  }
}
```

 Testes

 Unit Tests

```dart
void main() {
  group('GeoapifyService', () {
    test('getSuggestions returns list of places', () async {
      final service = GeoapifyService();
      final places = await service.getSuggestions(
        latitude: -.,
        longitude: -.,
        category: 'tourism.attraction',
      );
      
      expect(places, isNotEmpty);
      expect(places.first, isA<Place>());
    });
  });
}
```

---

Última atualização: Maio 
