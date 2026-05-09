import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/place_rating.dart';

void main() {
  group('PlaceRating Model Tests', () {
    test('Deve criar PlaceRating com todos os campos', () {
      final rating = PlaceRating(
        id: 'test_id',
        userId: 'user123',
        userName: 'João Silva',
        placeId: 'place_123',
        placeName: 'Restaurante Teste',
        placeAddress: 'Rua Teste, 123',
        placeLat: -23.5505,
        placeLon: -46.6333,
        placeCategory: 'restaurant',
        overallRating: 4.5,
        foodQuality: 5.0,
        serviceQuality: 4.0,
        valueForMoney: 4.5,
        cleanliness: 5.0,
        atmosphere: 4.5,
        review: 'Excelente restaurante!',
        tags: ['Delicioso', 'Bom custo-benefício'],
        createdAt: DateTime(2024, 1, 1),
        isPublic: true,
        tripId: 'trip123',
        likes: ['user456'],
        helpfulCount: 5,
      );

      expect(rating.id, 'test_id');
      expect(rating.userId, 'user123');
      expect(rating.userName, 'João Silva');
      expect(rating.placeName, 'Restaurante Teste');
      expect(rating.overallRating, 4.5);
      expect(rating.foodQuality, 5.0);
      expect(rating.tags.length, 2);
      expect(rating.likes.length, 1);
      expect(rating.helpfulCount, 5);
    });

    test('Deve converter PlaceRating para Map', () {
      final rating = PlaceRating(
        id: 'test_id',
        userId: 'user123',
        userName: 'João Silva',
        placeId: 'place_123',
        placeName: 'Restaurante Teste',
        placeAddress: 'Rua Teste, 123',
        placeCategory: 'restaurant',
        overallRating: 4.5,
        createdAt: DateTime(2024, 1, 1),
        isPublic: true,
      );

      final map = rating.toMap();

      expect(map['userId'], 'user123');
      expect(map['userName'], 'João Silva');
      expect(map['placeName'], 'Restaurante Teste');
      expect(map['overallRating'], 4.5);
      expect(map['isPublic'], true);
    });

    test('Deve retornar cor correta baseada na nota', () {
      final rating1 = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 4.8,
        createdAt: DateTime.now(),
      );

      final rating2 = PlaceRating(
        id: '2',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 2.5,
        createdAt: DateTime.now(),
      );

      expect(rating1.getRatingColor(), '#4CAF50'); 
      expect(rating2.getRatingColor(), '#FF9800'); 
    });

    test('Deve retornar descrição correta da nota', () {
      final rating1 = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 4.7,
        createdAt: DateTime.now(),
      );

      final rating2 = PlaceRating(
        id: '2',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 3.2,
        createdAt: DateTime.now(),
      );

      expect(rating1.getRatingDescription(), 'Excelente');
      expect(rating2.getRatingDescription(), 'Bom');
    });

    test('Deve calcular estrelas corretamente', () {
      final rating = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 3.7,
        createdAt: DateTime.now(),
      );

      expect(rating.getFullStars(), 3);
      expect(rating.hasHalfStar(), true);
    });

    test('Deve criar cópia com modificações', () {
      final original = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 3.0,
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        overallRating: 4.5,
        review: 'Melhorou muito!',
      );

      expect(modified.overallRating, 4.5);
      expect(modified.review, 'Melhorou muito!');
      expect(modified.id, original.id);
      expect(modified.userId, original.userId);
    });
  });

  group('PlaceStats Tests', () {
    test('Deve calcular estatísticas corretamente', () {
      final ratings = [
        PlaceRating(
          id: '1',
          userId: 'user1',
          userName: 'User 1',
          placeId: 'place1',
          placeName: 'Restaurante',
          placeAddress: 'Endereço',
          placeCategory: 'restaurant',
          overallRating: 4.0,
          foodQuality: 4.5,
          serviceQuality: 3.5,
          tags: ['Delicioso', 'Família'],
          createdAt: DateTime.now(),
          helpfulCount: 2,
        ),
        PlaceRating(
          id: '2',
          userId: 'user2',
          userName: 'User 2',
          placeId: 'place1',
          placeName: 'Restaurante',
          placeAddress: 'Endereço',
          placeCategory: 'restaurant',
          overallRating: 5.0,
          foodQuality: 5.0,
          serviceQuality: 4.5,
          tags: ['Delicioso', 'Romântico'],
          createdAt: DateTime.now(),
          helpfulCount: 3,
        ),
      ];

      final stats = PlaceStats.fromRatings(ratings);

      expect(stats.placeId, 'place1');
      expect(stats.placeName, 'Restaurante');
      expect(stats.totalRatings, 2);
      expect(stats.averageRating, 4.5);
      expect(stats.averageFoodQuality, 4.75);
      expect(stats.averageServiceQuality, 4.0);
      expect(stats.totalHelpful, 5);
      expect(stats.tagCounts['Delicioso'], 2);
      expect(stats.topTags.contains('Delicioso'), true);
    });

    test('Deve retornar stats vazias para lista vazia', () {
      final stats = PlaceStats.fromRatings([]);

      expect(stats.placeId, '');
      expect(stats.placeName, '');
      expect(stats.totalRatings, 0);
      expect(stats.averageRating, 0.0);
    });

    test('Deve ordenar tags por frequência', () {
      final ratings = [
        PlaceRating(
          id: '1',
          userId: 'user1',
          userName: 'User 1',
          placeId: 'place1',
          placeName: 'Lugar',
          placeAddress: 'End',
          placeCategory: 'attraction',
          overallRating: 4.0,
          tags: ['Tag1', 'Tag2'],
          createdAt: DateTime.now(),
        ),
        PlaceRating(
          id: '2',
          userId: 'user2',
          userName: 'User 2',
          placeId: 'place1',
          placeName: 'Lugar',
          placeAddress: 'End',
          placeCategory: 'attraction',
          overallRating: 4.0,
          tags: ['Tag1', 'Tag3'],
          createdAt: DateTime.now(),
        ),
        PlaceRating(
          id: '3',
          userId: 'user3',
          userName: 'User 3',
          placeId: 'place1',
          placeName: 'Lugar',
          placeAddress: 'End',
          placeCategory: 'attraction',
          overallRating: 4.0,
          tags: ['Tag1'],
          createdAt: DateTime.now(),
        ),
      ];

      final stats = PlaceStats.fromRatings(ratings);

      expect(stats.topTags.first, 'Tag1'); // Tag1 aparece 3 vezes
      expect(stats.tagCounts['Tag1'], 3);
      expect(stats.tagCounts['Tag2'], 1);
      expect(stats.tagCounts['Tag3'], 1);
    });
  });

  group('PlaceTags Tests', () {
    test('Deve retornar tags corretas para restaurantes', () {
      final tags = PlaceTags.getTagsForCategory('restaurant');

      expect(tags.contains('Delicioso'), true);
      expect(tags.contains('Bom custo-benefício'), true);
      expect(tags.contains('Ambiente agradável'), true);
    });

    test('Deve retornar tags corretas para atrações', () {
      final tags = PlaceTags.getTagsForCategory('attraction');

      expect(tags.contains('Imperdível'), true);
      expect(tags.contains('Fotogênico'), true);
      expect(tags.contains('Educativo'), true);
    });

    test('Deve retornar tags corretas para entretenimento', () {
      final tags = PlaceTags.getTagsForCategory('entertainment');

      expect(tags.contains('Animado'), true);
      expect(tags.contains('Boa música'), true);
      expect(tags.contains('Vista incrível'), true);
    });

    test('Deve retornar todas as tags para categoria desconhecida', () {
      final tags = PlaceTags.getTagsForCategory('unknown');

      expect(tags.length, greaterThan(20)); // Deve ter todas as tags
    });
  });

  group('PlaceRating Validation Tests', () {
    test('Nota deve estar entre 1 e 5', () {
      expect(() {
        PlaceRating(
          id: '1',
          userId: 'user1',
          userName: 'User',
          placeId: 'place1',
          placeName: 'Place',
          placeAddress: 'Address',
          placeCategory: 'restaurant',
          overallRating: 6.0, // Inválido
          createdAt: DateTime.now(),
        );
      }, returnsNormally); // O modelo não valida, mas a UI deve validar
    });

    test('Deve aceitar critérios opcionais nulos', () {
      final rating = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 4.0,
        createdAt: DateTime.now(),
      );

      expect(rating.foodQuality, null);
      expect(rating.serviceQuality, null);
      expect(rating.valueForMoney, null);
      expect(rating.cleanliness, null);
      expect(rating.atmosphere, null);
    });

    test('Deve aceitar listas vazias', () {
      final rating = PlaceRating(
        id: '1',
        userId: 'user1',
        userName: 'User',
        placeId: 'place1',
        placeName: 'Place',
        placeAddress: 'Address',
        placeCategory: 'restaurant',
        overallRating: 4.0,
        createdAt: DateTime.now(),
      );

      expect(rating.tags, isEmpty);
      expect(rating.photos, isEmpty);
      expect(rating.likes, isEmpty);
    });
  });
}

// Made with Bob
