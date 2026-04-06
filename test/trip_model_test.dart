import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/trip.dart';

void main() {
  group('Trip Admin Logic Tests', () {
    test('Should return true if user is the ownerId', () {
      final trip = Trip(
        id: '123',
        ownerId: 'user_adm',
        destination: 'Paris',
        budget: 1000,
        objective: 'Tour',
        createdAt: DateTime.now(),
        members: ['user_adm', 'user_member'],
      );

      expect(trip.isAdmin('user_adm'), isTrue);
      expect(trip.isAdmin('user_member'), isFalse);
    });

    test('Should return true for the first member if ownerId is empty (legacy support)', () {
      final trip = Trip(
        id: '123',
        ownerId: '', // Viagem antiga
        destination: 'London',
        budget: 1000,
        objective: 'Tour',
        createdAt: DateTime.now(),
        members: ['first_user', 'second_user'],
      );

      expect(trip.isAdmin('first_user'), isTrue);
      expect(trip.isAdmin('second_user'), isFalse);
    });

    test('Should return false if uid is empty', () {
      final trip = Trip(
        id: '123',
        ownerId: 'adm',
        destination: 'NY',
        budget: 500,
        objective: 'Work',
        createdAt: DateTime.now(),
      );

      expect(trip.isAdmin(''), isFalse);
    });
  });
}
