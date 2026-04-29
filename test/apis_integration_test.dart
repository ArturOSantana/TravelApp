import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/services/geoapify_service.dart';
import 'package:travel_app/services/openweathermap_service.dart';

void main() {
  group('Geoapify Service Tests', () {
    test('Deve buscar atrações turísticas', () async {
      final attractions = await GeoapifyService.searchPlaces(
        lat: 48.8566,
        lon: 2.3522,
        categories: 'tourism.attraction,tourism.sights,heritage',
        radius: 5000,
        limit: 10,
      );

      expect(attractions, isNotEmpty);
      expect(attractions.first, containsPair('name', isNotNull));
      expect(attractions.first, containsPair('lat', isNotNull));
      expect(attractions.first, containsPair('lon', isNotNull));
    });

    test('Deve buscar restaurantes', () async {
      final restaurants = await GeoapifyService.searchPlaces(
        lat: -23.5505,
        lon: -46.6333,
        categories: 'catering.restaurant,catering.cafe,catering.fast_food',
        radius: 5000,
        limit: 10,
      );

      expect(restaurants, isNotEmpty);
      expect(restaurants.first, containsPair('name', isNotNull));
      expect(restaurants.first, containsPair('address', isNotNull));
    });

    test('Deve buscar entretenimento', () async {
      // Rio de Janeiro coordinates
      final entertainment = await GeoapifyService.searchPlaces(
        lat: -22.9068,
        lon: -43.1729,
        categories: 'entertainment,leisure,sport',
        radius: 5000,
        limit: 10,
      );

      expect(entertainment, isNotEmpty);
      expect(entertainment.first, containsPair('name', isNotNull));
    });

    test('Deve retornar lista vazia para coordenadas inválidas', () async {
      final results = await GeoapifyService.searchPlaces(
        lat: 999.0,
        lon: 999.0,
        categories: 'tourism',
        radius: 5000,
        limit: 10,
      );

      expect(results, isEmpty);
    });
  });

  group('OpenWeatherMap Service Tests', () {
    test('Deve buscar clima atual de uma cidade', () async {
      final weather = await OpenWeatherMapService.getCurrentWeather('Paris');

      expect(weather, isNotNull);
      expect(weather!['temp'], isNotNull);
      expect(weather['description'], isNotNull);
      expect(weather['humidity'], isNotNull);
      expect(weather['wind_speed'], isNotNull);
    });

    test('Deve buscar previsão de 5 dias', () async {
      final forecast = await OpenWeatherMapService.getForecast('London');

      expect(forecast, isNotNull);
      expect(forecast!, isNotEmpty);
      expect(forecast.length,
          greaterThan(10)); // Pelo menos 10 previsões (3h cada)
      expect(forecast.first, containsPair('temp', isNotNull));
      expect(forecast.first, containsPair('description', isNotNull));
      expect(forecast.first,
          containsPair('pop', isNotNull)); // Probabilidade de chuva
    });

    test('Deve buscar clima por coordenadas', () async {
      // Tokyo coordinates
      final weather = await OpenWeatherMapService.getCurrentWeatherByCoords(
        35.6762,
        139.6503,
      );

      expect(weather, isNotNull);
      expect(weather!['temp'], isNotNull);
      expect(weather['city_name'], isNotNull);
    });

    test('Deve retornar URL do ícone do clima', () {
      final iconUrl = OpenWeatherMapService.getIconUrl('01d');

      expect(iconUrl, contains('openweathermap.org'));
      expect(iconUrl, contains('01d'));
      expect(iconUrl, endsWith('@2x.png'));
    });

    test('Deve converter código do ícone para emoji', () {
      expect(OpenWeatherMapService.getWeatherEmoji('01d'), equals('☀️'));
      expect(OpenWeatherMapService.getWeatherEmoji('09d'), equals('🌧️'));
      expect(OpenWeatherMapService.getWeatherEmoji('11d'), equals('⛈️'));
      expect(OpenWeatherMapService.getWeatherEmoji('13d'), equals('❄️'));
    });

    test('Deve retornar direção do vento', () {
      expect(OpenWeatherMapService.getWindDirection(0), equals('Norte'));
      expect(OpenWeatherMapService.getWindDirection(90), equals('Leste'));
      expect(OpenWeatherMapService.getWindDirection(180), equals('Sul'));
      expect(OpenWeatherMapService.getWindDirection(270), equals('Oeste'));
    });

    test('Deve agrupar previsões por dia', () async {
      final forecast = await OpenWeatherMapService.getForecast('Paris');
      expect(forecast, isNotNull);

      final grouped = OpenWeatherMapService.groupForecastByDay(forecast!);

      expect(grouped, isNotEmpty);
      expect(grouped.length, lessThanOrEqualTo(6)); // Máximo 6 dias
      expect(grouped.first, containsPair('temp_avg', isNotNull));
      expect(grouped.first, containsPair('temp_min', isNotNull));
      expect(grouped.first, containsPair('temp_max', isNotNull));
    });
  });

  // Testes do ExternalAppsService foram removidos pois dependem de
  // objetos Activity e são melhor testados manualmente no app

  group('Integration Tests', () {
    test('Deve buscar sugestões completas para uma viagem', () async {
      // Simular busca completa de sugestões para Paris
      final lat = 48.8566;
      final lon = 2.3522;

      final results = await Future.wait([
        GeoapifyService.searchPlaces(
          lat: lat,
          lon: lon,
          categories: 'tourism.attraction',
          radius: 5000,
          limit: 5,
        ),
        GeoapifyService.searchPlaces(
          lat: lat,
          lon: lon,
          categories: 'catering.restaurant',
          radius: 5000,
          limit: 5,
        ),
        OpenWeatherMapService.getCurrentWeather('Paris'),
      ]);

      final attractions = results[0] as List<Map<String, dynamic>>;
      final restaurants = results[1] as List<Map<String, dynamic>>;
      final weather = results[2] as Map<String, dynamic>?;

      expect(attractions, isNotEmpty);
      expect(restaurants, isNotEmpty);
      expect(weather, isNotNull);
    });

    test('Deve lidar com falhas de API graciosamente', () async {
      // Testar com cidade inexistente
      final weather = await OpenWeatherMapService.getCurrentWeather(
          'CidadeInexistente123456');

      // Deve retornar null em vez de dar erro
      expect(weather, isNull);
    });

    test('Deve lidar com coordenadas inválidas', () async {
      final places = await GeoapifyService.searchPlaces(
        lat: 999.0,
        lon: 999.0,
        categories: 'tourism',
        radius: 5000,
        limit: 10,
      );

      // Deve retornar lista vazia em vez de dar erro
      expect(places, isEmpty);
    });
  });

  group('Performance Tests', () {
    test('Busca de locais deve ser rápida (< 5 segundos)', () async {
      final stopwatch = Stopwatch()..start();

      await GeoapifyService.searchPlaces(
        lat: 48.8566,
        lon: 2.3522,
        categories: 'tourism.attraction',
        radius: 5000,
        limit: 10,
      );

      stopwatch.stop();
      expect(stopwatch.elapsed.inSeconds, lessThan(5));
    });

    test('Busca de clima deve ser rápida (< 3 segundos)', () async {
      final stopwatch = Stopwatch()..start();

      await OpenWeatherMapService.getCurrentWeather('Paris');

      stopwatch.stop();
      expect(stopwatch.elapsed.inSeconds, lessThan(3));
    });
  });
}

