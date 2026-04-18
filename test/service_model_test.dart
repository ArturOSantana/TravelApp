import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/service_model.dart';

void main() {
  group('ServiceModel Test', () {
    final now = DateTime.now();
    
    test('Deve criar uma instancia valida e converter para mapa', () {
      final service = ServiceModel(
        id: '1',
        ownerId: 'user1',
        name: 'Restaurante Teste',
        category: 'Restaurante',
        location: 'Sao Paulo',
        rating: 4.5,
        comment: 'Muito bom',
        averageCost: 50.0,
        lastUsed: now,
        savedBy: ['user2'],
        likes: ['user3'],
      );

      final map = service.toMap();

      expect(map['name'], 'Restaurante Teste');
      expect(map['ownerId'], 'user1');
      expect(map['savedBy'], contains('user2'));
      expect(map['likes'], contains('user3'));
    });

    test('copyWith deve atualizar apenas campos selecionados', () {
      final service = ServiceModel(
        id: '1',
        ownerId: 'user1',
        name: 'Original',
        category: 'Cat',
        location: 'Loc',
        rating: 5.0,
        comment: 'Coment',
        averageCost: 10.0,
        lastUsed: now,
      );

      final updated = service.copyWith(name: 'Atualizado');

      expect(updated.name, 'Atualizado');
      expect(updated.ownerId, 'user1'); // Deve manter o original
    });
  });
}
