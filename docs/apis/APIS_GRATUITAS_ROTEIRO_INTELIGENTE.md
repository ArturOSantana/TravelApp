  APIs Gratuitas para Roteiro Inteligente

Documentação das APIs gratuitas integradas ao Travel App para fornecer sugestões inteligentes de atividades e informações de viagem.

  Visão Geral

O Travel App utiliza múltiplas APIs gratuitas para enriquecer a experiência do usuário com:
- Sugestões de locais e atividades
- Informações meteorológicas
- Dados de países e moedas
- Geocoding e mapas

---

 ️ Geoapify API

 Descrição
API de geolocalização e pontos de interesse (POI) que fornece sugestões de locais baseadas em categorias.

 Recursos Utilizados
- Places API - Busca de pontos de interesse
- Geocoding API - Conversão de endereços
- Routing API - Cálculo de rotas

 Plano Gratuito
-  . requisições/dia
-  Sem necessidade de cartão de crédito
-  Dados atualizados do OpenStreetMap

 Categorias Suportadas
- `tourism.attraction` - Atrações turísticas
- `catering.restaurant` - Restaurantes
- `catering.cafe` - Cafés
- `entertainment` - Entretenimento
- `accommodation.hotel` - Hotéis
- `commercial.shopping_mall` - Shopping centers

 Exemplo de Uso
```dart
final service = GeoapifyService();
final suggestions = await service.getSuggestions(
  latitude: -.,
  longitude: -.,
  category: 'tourism.attraction',
  radius: ,
);
```

 Documentação
- [Geoapify Docs](https://www.geoapify.com/docs)
- [API Reference](https://apidocs.geoapify.com)

---

 ️ OpenWeatherMap API

 Descrição
API de previsão do tempo com dados meteorológicos detalhados.

 Recursos Utilizados
- Current Weather - Clima atual
-  Day Forecast - Previsão de  dias
- Weather Alerts - Alertas meteorológicos

 Plano Gratuito
-  . requisições/dia
-  Dados atualizados a cada  minutos
-  Cobertura global

 Dados Fornecidos
- Temperatura (atual, mínima, máxima)
- Umidade e pressão atmosférica
- Velocidade e direção do vento
- Probabilidade de chuva
- Nascer e pôr do sol
- Índice UV

 Exemplo de Uso
```dart
final service = OpenWeatherMapService();
final weather = await service.getCurrentWeather(
  latitude: -.,
  longitude: -.,
);
```

 Documentação
- [OpenWeatherMap Docs](https://openweathermap.org/api)
- [API Guide](https://openweathermap.org/guide)

---

  REST Countries API

 Descrição
API pública com informações detalhadas sobre todos os países do mundo.

 Recursos Utilizados
- Informações gerais do país
- Moeda oficial
- Idiomas falados
- Fuso horário
- Bandeira e capital

 Plano Gratuito
-  Completamente gratuito
-  Sem limite de requisições
-  Sem necessidade de API key

 Dados Fornecidos
- Nome oficial e comum
- Capital e população
- Área territorial
- Moedas e símbolos
- Idiomas oficiais
- Código de discagem
- Fuso horário

 Exemplo de Uso
```dart
final service = RestCountriesService();
final countryInfo = await service.getCountryInfo('Brazil');
```

 Documentação
- [REST Countries](https://restcountries.com)
- [API Docs](https://restcountries.com/api-endpoints-v)

---

  ExchangeRate API

 Descrição
API de taxas de câmbio em tempo real para conversão de moedas.

 Recursos Utilizados
- Latest Rates - Taxas atuais
- Historical Rates - Taxas históricas
- Currency Conversion - Conversão direta

 Plano Gratuito
-  . requisições/mês
-  Atualização diária
-   moedas suportadas

 Moedas Principais
- USD, EUR, GBP, JPY
- BRL, ARS, CLP, MXN
- AUD, CAD, CHF, CNY

 Exemplo de Uso
```dart
final service = ExchangeRateService();
final rate = await service.getExchangeRate(
  from: 'USD',
  to: 'BRL',
);
```

 Documentação
- [ExchangeRate-API](https://www.exchangerate-api.com)
- [API Docs](https://www.exchangerate-api.com/docs)

---

 ️ Nominatim (OpenStreetMap)

 Descrição
Serviço de geocoding gratuito baseado no OpenStreetMap.

 Recursos Utilizados
- Search - Busca de endereços
- Reverse Geocoding - Coordenadas para endereço
- Lookup - Detalhes de locais

 Plano Gratuito
-  Completamente gratuito
-  Limite:  requisição/segundo
-  Dados do OpenStreetMap

 Exemplo de Uso
```dart
final url = 'https://nominatim.openstreetmap.org/search';
final response = await http.get(
  Uri.parse('$url?q=São Paulo&format=json'),
);
```

 Documentação
- [Nominatim](https://nominatim.org)
- [Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)

---

  Gerenciamento de API Keys

 Estrutura de Configuração

Crie o arquivo `lib/config/api_keys.dart`:

```dart
class ApiKeys {
  // Geoapify
  static const String geoapify = 'YOUR_GEOAPIFY_KEY';
  
  // OpenWeatherMap
  static const String openWeatherMap = 'YOUR_OPENWEATHERMAP_KEY';
  
  // ExchangeRate
  static const String exchangeRate = 'YOUR_EXCHANGERATE_KEY';
  
  // Outras APIs não precisam de key
}
```

 Segurança

️ IMPORTANTE: Nunca commite API keys no Git!

Adicione ao `.gitignore`:
```
lib/config/api_keys.dart
```

Use o arquivo de exemplo:
```
lib/config/api_keys.dart.example
```

---


  Otimizações

 Cache de Dados
```dart
class CacheService {
  static Future<void> cacheApiResponse(
    String key,
    dynamic data,
    Duration ttl,
  ) async {
    // Implementação de cache
  }
}
```

 Rate Limiting
```dart
class RateLimiter {
  static Future<void> throttle(Duration delay) async {
    await Future.delayed(delay);
  }
}
```

 Fallback Strategy
```dart
try {
  final data = await primaryApi.fetch();
} catch (e) {
  final data = await fallbackApi.fetch();
}
```

---

  Recursos Adicionais

- [Geoapify Dashboard](https://myprojects.geoapify.com)
- [OpenWeatherMap Dashboard](https://home.openweathermap.org)
- [ExchangeRate Dashboard](https://app.exchangerate-api.com)

---

Última atualização: Maio   
Versão: ..
