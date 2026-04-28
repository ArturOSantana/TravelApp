import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/models/activity.dart';
import 'package:travel_app/models/expense.dart';
import 'package:travel_app/models/journal_entry.dart';
import 'package:travel_app/models/service_model.dart';

void main() {
  group('Gestão de Itinerários e Grupos', () {
    test('Deve validar a integridade de uma Viagem Solo', () {
      final trip = Trip(
        id: '123',
        ownerId: 'user_dev',
        destination: 'Paris',
        budget: 15000.0,
        objective: 'Lazer',
        createdAt: DateTime.now(),
        isNomad: false,
        isGroup: false,
      );

      expect(trip.destination, equals('Paris'));
      expect(trip.isGroup, isFalse);
    });

    test('Deve validar a hierarquia de permissões (ADM vs Membro)', () {
      final trip = Trip(
        id: 'group_456',
        ownerId: 'admin_id',
        destination: 'Roma',
        budget: 5000,
        objective: 'Cultura',
        isGroup: true,
        members: ['admin_id', 'member_id'],
        createdAt: DateTime.now(),
      );

      expect(trip.isAdmin('admin_id'), isTrue);
      expect(trip.isAdmin('member_id'), isFalse);
    });
  });

  group('Lógica Financeira e Divisão de Custos', () {
    test('Deve validar o registro de despesa e categorias', () {
      final expense = Expense(
        id: 'exp_01',
        tripId: 'trip_01',
        title: 'Jantar',
        value: 250.50,
        originalValue: 250.50,
        currency: 'BRL',
        category: 'food',
        payerId: 'user_01',
        date: DateTime.now(),
      );

      expect(expense.value, 250.50);
      expect(expense.originalValue, 250.50);
      expect(expense.currency, 'BRL');
      expect(expense.category, 'food');
    });

    test('Deve validar o algoritmo de split (divisão de gastos)', () {
      final expense = Expense(
        id: 'exp_split',
        tripId: 'trip_group',
        title: 'Hotel',
        value: 900.0,
        originalValue: 900.0,
        currency: 'BRL',
        category: 'lodging',
        payerId: 'admin',
        splitType: SplitType.exact,
        splits: {'user_1': 300.0, 'user_2': 300.0, 'admin': 300.0},
        date: DateTime.now(),
      );

      final totalSplit = expense.splits.values.fold<double>(
        0.0,
        (acc, item) => acc + item,
      );
      expect(totalSplit, equals(expense.value));
      expect(expense.splits['user_1'], 300.0);
      expect(expense.splitType, SplitType.exact);
    });

    test(
      'Deve serializar despesa mantendo tipo de divisão e participantes',
      () {
        final expense = Expense(
          id: 'exp_map',
          tripId: 'trip_map',
          title: 'Passeio',
          value: 120.0,
          originalValue: 20.0,
          currency: 'USD',
          category: 'leisure',
          payerId: 'user_01',
          splitType: SplitType.percentage,
          splits: {'user_01': 50.0, 'user_02': 50.0},
          date: DateTime(2026, 1, 10),
        );

        final map = expense.toMap();

        expect(map['tripId'], 'trip_map');
        expect(map['currency'], 'USD');
        expect(map['splitType'], 'percentage');
        expect(map['splits'], {'user_01': 50.0, 'user_02': 50.0});
      },
    );
  });

  group('Roteirização e Governança', () {
    test('Deve processar votos em atividades colaborativas', () {
      final activity = Activity(
        id: 'act_01',
        tripId: 'trip_01',
        title: 'Passeio de Barco',
        time: DateTime.now(),
        location: 'Veneza',
        category: 'leisure',
        votes: {
          'user_1': 1, // Aprova
          'user_2': 1, // Aprova
          'user_3': -1, // Reprova
        },
      );

      int saldoVotos = activity.votes.values.reduce((a, b) => a + b);
      expect(saldoVotos, equals(1)); // 2 positivos - 1 negativo
    });
  });

  group('Documentação e Diário de Bordo', () {
    test('Deve validar entrada de diário com métrica de humor', () {
      final entry = JournalEntry(
        id: 'j_01',
        tripId: 'trip_01',
        userId: 'user_01',
        userName: 'Artur',
        date: DateTime.now(),
        content: 'Experiência fantástica no museu.',
        mood: MoodIcon.veryHappy,
        locationName: 'Louvre',
        createdAt: DateTime.now(),
      );

      expect(entry.mood, equals(MoodIcon.veryHappy));
      expect(entry.content, contains('fantástica'));
    });
  });

  group('Serviços e Comunidade', () {
    test('Deve validar modelo de recomendação pública', () {
      final service = ServiceModel(
        id: 'srv_01',
        ownerId: 'user_01',
        name: 'Restaurante Central',
        category: 'Gastronomia',
        location: 'São Paulo',
        rating: 4.8,
        comment: 'Excelente custo-benefício.',
        averageCost: 85.0,
        lastUsed: DateTime.now(),
        isPublic: true,
      );

      expect(service.isPublic, isTrue);
      expect(service.rating, equals(4.8));
    });
  });
}
