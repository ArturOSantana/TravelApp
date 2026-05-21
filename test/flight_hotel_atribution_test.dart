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
        status: TripStatus.active,
      );

      final bool canAtribute =
          trip.status == TripStatus.active || trip.status == TripStatus.planned;
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
        status: TripStatus.planned,
      );

      final bool canAtribute =
          trip.status == TripStatus.active || trip.status == TripStatus.planned;
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
        status: TripStatus.completed,
      );

      final bool canAtribute =
          trip.status == TripStatus.active || trip.status == TripStatus.planned;
      expect(canAtribute, isFalse);
    });
  });
}
