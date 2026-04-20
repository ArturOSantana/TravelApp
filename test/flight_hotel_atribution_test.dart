import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/trip.dart';

void main() {
  group('Trip Status Validation for Attribution', () {
    test('Should allow attribution for active trips', () {
      final trip = Trip(
        id: '1',
        ownerId: 'u1',
        destination: 'Paris',
        budget: 5000,
        objective: 'Leisure',
        createdAt: DateTime.now(),
        status: 'active',
      );

      final bool canAtribute = trip.status == 'active' || trip.status == 'planned';
      expect(canAtribute, isTrue);
    });

    test('Should allow attribution for planned trips', () {
      final trip = Trip(
        id: '2',
        ownerId: 'u1',
        destination: 'Tokyo',
        budget: 15000,
        objective: 'Leisure',
        createdAt: DateTime.now(),
        status: 'planned',
      );

      final bool canAtribute = trip.status == 'active' || trip.status == 'planned';
      expect(canAtribute, isTrue);
    });

    test('Should NOT allow attribution for completed trips', () {
      final trip = Trip(
        id: '3',
        ownerId: 'u1',
        destination: 'Rome',
        budget: 3000,
        objective: 'Leisure',
        createdAt: DateTime.now(),
        status: 'completed',
      );

      final bool canAtribute = trip.status == 'active' || trip.status == 'planned';
      expect(canAtribute, isFalse);
    });
  });
}
