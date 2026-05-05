 ️ Alternativa: OpenTripMap

 Visão Geral

OpenTripMap é uma API gratuita de pontos turísticos baseada em dados do OpenStreetMap e Wikipedia.

 Recursos

 Plano Gratuito
-  Completamente gratuito
-  Sem limite de requisições
-  Dados de Wikipedia
-  Fotos e descrições

 Dados Disponíveis
- Atrações turísticas
- Monumentos históricos
- Museus e galerias
- Parques e natureza
- Arquitetura

 Implementação

 Exemplo de Uso

```dart
class OpenTripMapService {
  static const String _baseUrl = 'https://api.opentripmap.com/.';
  static const String _apiKey = 'YOUR_API_KEY';
  
  Future<List<Attraction>> getAttractions({
    required double latitude,
    required double longitude,
    int radius = ,
  }) async {
    final url = '$_baseUrl/en/places/radius'
        '?radius=$radius'
        '&lon=$longitude'
        '&lat=$latitude'
        '&apikey=$_apiKey';
    
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    
    return (data as List)
        .map((a) => Attraction.fromJson(a))
        .toList();
  }
}
```

 Recomendação

Use ambas as APIs de forma complementar:
- OpenTripMap: Para atrações turísticas
- Geoapify: Para restaurantes, hotéis, etc.

---

Última atualização: Maio 
