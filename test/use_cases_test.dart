import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/models/activity.dart';
import 'package:travel_app/models/expense.dart';
import 'package:travel_app/models/journal_entry.dart';

void main() {
  group('Caso de Uso 1 & 2: Gerenciamento de Viagens', () {
    test('Deve criar uma viagem solo com os parâmetros corretos', () {
      final trip = Trip(
        id: 'trip1',
        ownerId: 'user1',
        destination: 'Japão',
        budget: 5000.0,
        objective: 'Cultura',
        createdAt: DateTime.now(),
        isNomad: false,
        isGroup: false,
      );

      expect(trip.destination, 'Japão');
      expect(trip.isNomad, isFalse);
      expect(trip.isGroup, isFalse);
    });

    test('Deve validar modo Nômade (viagem sem data final)', () {
      final trip = Trip(
        id: 'trip2',
        ownerId: 'user1',
        destination: 'Mundo',
        budget: 0,
        objective: 'Exploração',
        isNomad: true,
        startDate: DateTime.now(),
        endDate: null, // Sem data final
        createdAt: DateTime.now(),
      );

      expect(trip.isNomad, isTrue);
      expect(trip.endDate, isNull);
    });

    test('Deve validar permissões de ADM em viagem de grupo', () {
      final trip = Trip(
        id: 'trip_group',
        ownerId: 'admin_user',
        destination: 'Florianópolis',
        budget: 2000,
        objective: 'Lazer',
        isGroup: true,
        members: ['admin_user', 'member_user'],
        createdAt: DateTime.now(),
      );

      expect(trip.isAdmin('admin_user'), isTrue);
      expect(trip.isAdmin('member_user'), isFalse);
    });
  });

  group('Caso de Uso 3 & 4: Roteiro e Votação', () {
    test('Deve criar atividade com categoria e localização', () {
      final activity = Activity(
        id: 'act1',
        tripId: 'trip1',
        title: 'Visita ao Templo',
        time: DateTime.now(),
        location: 'Kyoto',
        category: 'culture',
      );

      expect(activity.category, 'culture');
      expect(activity.location, 'Kyoto');
    });

    test('Deve registrar votos em uma atividade de grupo', () {
      final activity = Activity(
        id: 'act_vote',
        tripId: 'trip_group',
        title: 'Jantar no Centro',
        time: DateTime.now(),
        location: 'Centro',
        votes: {
          'user1': 1, // Aprovou
          'user2': -1, // Reprovou
          'user3': 1, // Aprovou
        },
      );

      // Lógica de contagem simples
      int totalVotes = activity.votes.values.reduce((a, b) => a + b);
      expect(totalVotes, 1); // 2 prós, 1 contra = 1 positivo
    });
  });

  group('Caso de Uso 5 & 6: Controle Financeiro', () {
    test('Deve registrar gasto individual e categoria', () {
      final expense = Expense(
        id: 'exp1',
        tripId: 'trip1',
        title: 'Almoço',
        value: 50.0,
        category: 'food',
        payerId: 'user1',
        date: DateTime.now(),
      );

      expect(expense.value, 50.0);
      expect(expense.category, 'food');
    });

    test('Deve calcular divisão de gastos em grupo (Quem deve para quem)', () {
      final expense = Expense(
        id: 'exp_group',
        tripId: 'trip_group',
        title: 'Hospedagem',
        value: 300.0,
        category: 'lodging',
        payerId: 'user_admin',
        splits: {
          'user_admin': 100.0,
          'user_member1': 100.0,
          'user_member2': 100.0,
        },
        date: DateTime.now(),
      );

      expect(expense.splits.length, 3);
      expect(expense.splits['user_member1'], 100.0);
    });
  });

  group('Caso de Uso 7 & 13: Diário e Serviços', () {
    test('Deve permitir registro de diário com humor (score) e avaliação', () {
      final entry = JournalEntry(
        id: 'journal1',
        tripId: 'trip1',
        date: DateTime.now(),
        content: 'Dia incrível no templo!',
        moodScore: 5.0, // Escala de 1 a 5
        locationName: 'Templo Kinkaku-ji',
        createdAt: DateTime.now(),
      );

      expect(entry.moodScore, 5.0);
      expect(entry.content, contains('incrível'));
    });
  });
}
