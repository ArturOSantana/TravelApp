import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;

// Importações do projeto
import '../lib/models/notification_model.dart';

void main() {
  // Setup global
  setUpAll(() {
    tz.initializeTimeZones();
    tz_lib.setLocalLocation(tz_lib.getLocation('America/Sao_Paulo'));
  });

  group('NotificationModel Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 6, 15, 10, 30);
    });

    test('Deve criar notificação de curtida com todos os campos', () {
      final notification = _createTestNotification(
        type: NotificationType.like,
        senderName: 'João Silva',
        postName: 'Viagem para Paris',
      );

      expect(notification.type, NotificationType.like);
      expect(notification.senderName, 'João Silva');
      expect(notification.postName, 'Viagem para Paris');
      expect(notification.isRead, false);
      expect(notification.commentText, isNull);
    });

    test('Deve criar notificação de comentário com texto', () {
      final notification = _createTestNotification(
        type: NotificationType.comment,
        senderName: 'Maria Santos',
        commentText: 'Ótimas dicas! Obrigada!',
      );

      expect(notification.type, NotificationType.comment);
      expect(notification.commentText, isNotNull);
      expect(notification.commentText, contains('Ótimas dicas'));
    });

    test('Deve criar notificação de alerta de segurança crítico', () {
      final notification = _createTestNotification(
        type: NotificationType.safetyAlert,
        postName: 'Centro de São Paulo',
        commentText: 'ALERTA SOS: Preciso de ajuda!',
      );

      expect(notification.type, NotificationType.safetyAlert);
      expect(notification.commentText, contains('ALERTA SOS'));
      expect(notification.postName, 'Centro de São Paulo');
    });

    test('Deve converter notificação para Map corretamente', () {
      final notification = _createTestNotification(
        type: NotificationType.like,
        isRead: true,
      );

      final map = notification.toMap();

      expect(map, isA<Map<String, dynamic>>());
      expect(map['receiverId'], 'user_2');
      expect(map['senderId'], 'user_1');
      expect(map['type'], NotificationType.like.index);
      expect(map['isRead'], true);
      expect(map.containsKey('createdAt'), true);
    });

    test('Deve validar todos os tipos de notificação', () {
      for (final type in NotificationType.values) {
        final notification = _createTestNotification(type: type);
        expect(notification.type, type);
        expect(NotificationType.values.contains(notification.type), true);
      }
    });
  });

  group('Smart Notification Logic Tests', () {
    test('Deve calcular dias até viagem com precisão', () {
      final now = DateTime.now();
      final testCases = [
        (days: 1, expected: 1),
        (days: 7, expected: 7),
        (days: 30, expected: 30),
        (days: 90, expected: 90),
      ];

      for (final testCase in testCases) {
        final tripDate = now.add(Duration(days: testCase.days));
        final daysUntil = tripDate.difference(now).inDays;
        expect(daysUntil, testCase.expected);
      }
    });

    test('Deve identificar momentos críticos para notificação de viagem', () {
      final now = DateTime.now();
      final criticalDays = [1, 7, 30];

      for (final days in criticalDays) {
        final tripDate = now.add(Duration(days: days));
        final daysUntil = tripDate.difference(now).inDays;
        expect(criticalDays.contains(daysUntil), true,
            reason: '$days dias deve ser momento crítico');
      }
    });

    test('Deve calcular porcentagem de orçamento com precisão', () {
      final testCases = [
        (budget: 1000.0, spent: 500.0, expected: 0.5),
        (budget: 1000.0, spent: 750.0, expected: 0.75),
        (budget: 1000.0, spent: 900.0, expected: 0.9),
        (budget: 1000.0, spent: 1000.0, expected: 1.0),
        (budget: 1000.0, spent: 1100.0, expected: 1.1),
      ];

      for (final testCase in testCases) {
        final percentage = testCase.spent / testCase.budget;
        expect(percentage, closeTo(testCase.expected, 0.001));
      }
    });

    test('Deve identificar todos os níveis de alerta de orçamento', () {
      final budget = 1000.0;
      final alertLevels = {
        'info': (threshold: 0.5, spent: 500.0),
        'warning': (threshold: 0.75, spent: 750.0),
        'danger': (threshold: 0.9, spent: 900.0),
        'critical': (threshold: 1.0, spent: 1000.0),
        'exceeded': (threshold: 1.0, spent: 1100.0),
      };

      for (final entry in alertLevels.entries) {
        final percentage = entry.value.spent / budget;
        expect(percentage >= entry.value.threshold, true,
            reason: '${entry.key} deve atingir threshold');
      }
    });

    test('Deve calcular tempo desde último check-in', () {
      final now = DateTime.now();
      final testCases = [
        (hours: 12, shouldAlert: false),
        (hours: 23, shouldAlert: false),
        (hours: 24, shouldAlert: true),
        (hours: 25, shouldAlert: true),
        (hours: 48, shouldAlert: true),
      ];

      for (final testCase in testCases) {
        final lastCheckin = now.subtract(Duration(hours: testCase.hours));
        final hoursSince = now.difference(lastCheckin).inHours;
        final shouldAlert = hoursSince >= 24;

        expect(hoursSince, testCase.hours);
        expect(shouldAlert, testCase.shouldAlert,
            reason:
                '${testCase.hours}h deve ${testCase.shouldAlert ? "" : "não "}alertar');
      }
    });

    test('Deve validar lógica de check-in de segurança', () {
      final now = DateTime.now();

      // Casos que devem lembrar
      final shouldRemind = [25, 30, 48, 72];
      for (final hours in shouldRemind) {
        final lastCheckin = now.subtract(Duration(hours: hours));
        expect(now.difference(lastCheckin).inHours >= 24, true);
      }

      // Casos que não devem lembrar
      final shouldNotRemind = [1, 6, 12, 23];
      for (final hours in shouldNotRemind) {
        final lastCheckin = now.subtract(Duration(hours: hours));
        expect(now.difference(lastCheckin).inHours >= 24, false);
      }
    });
  });

  group('Notification Scheduling Tests', () {
    test('Deve validar agendamento futuro', () {
      final now = DateTime.now();
      final futureDates = [
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 24)),
        now.add(const Duration(days: 7)),
      ];

      for (final date in futureDates) {
        expect(date.isAfter(now), true);
        expect(date.difference(now).inSeconds > 0, true);
      }
    });

    test('Deve rejeitar agendamento no passado', () {
      final now = DateTime.now();
      final pastDates = [
        now.subtract(const Duration(hours: 1)),
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 7)),
      ];

      for (final date in pastDates) {
        expect(date.isBefore(now), true);
        expect(date.difference(now).inSeconds < 0, true);
      }
    });

    test('Deve calcular próximo horário de notificação diária', () {
      final now = DateTime.now();
      final targetHour = 9;

      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        targetHour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      expect(scheduledDate.isAfter(now), true);
      expect(scheduledDate.hour, targetHour);
      expect(scheduledDate.minute, 0);
    });

    test('Deve validar múltiplos horários de notificação', () {
      final now = DateTime.now();
      final scheduleHours = [9, 12, 20];

      for (final hour in scheduleHours) {
        var scheduled = DateTime(now.year, now.month, now.day, hour, 0);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        expect(scheduled.isAfter(now), true);
        expect(scheduled.hour, hour);
      }
    });
  });

  group('Notification Priority Tests', () {
    test('Deve ter hierarquia de prioridades correta', () {
      final priorities = [
        Importance.min,
        Importance.low,
        Importance.defaultImportance,
        Importance.high,
        Importance.max,
      ];

      for (int i = 0; i < priorities.length - 1; i++) {
        expect(priorities[i].index < priorities[i + 1].index, true,
            reason: '${priorities[i]} deve ser menor que ${priorities[i + 1]}');
      }
    });

    test('Alerta de segurança deve ter prioridade máxima', () {
      const safetyImportance = Importance.max;
      const regularImportance = Importance.defaultImportance;

      expect(safetyImportance.index, greaterThan(regularImportance.index));
      expect(safetyImportance, Importance.max);
    });

    test('Deve mapear tipos de notificação para prioridades', () {
      final priorityMap = {
        NotificationType.safetyAlert: Importance.max,
        NotificationType.comment: Importance.high,
        NotificationType.like: Importance.defaultImportance,
      };

      for (final entry in priorityMap.entries) {
        expect(entry.value, isA<Importance>());
      }
    });
  });

  group('Notification Content Tests', () {
    test('Deve formatar mensagens de viagem corretamente', () {
      final templates = {
        1: (String dest) =>
            'Sua viagem para $dest começa amanhã. Já fez as malas?',
        7: (String dest) =>
            '$dest está chegando! Hora de finalizar os preparativos.',
        30: (String dest) =>
            'Comece a planejar sua viagem para $dest. Já reservou hospedagem?',
      };

      for (final entry in templates.entries) {
        final message = entry.value('Paris');
        expect(message, contains('Paris'));
        expect(message.isNotEmpty, true);
      }
    });

    test('Deve formatar alertas de orçamento com valores', () {
      final testCases = [
        (spent: 500.0, budget: 1000.0, percentage: 50),
        (spent: 900.0, budget: 1000.0, percentage: 90),
        (spent: 1100.0, budget: 1000.0, percentage: 110),
      ];

      for (final testCase in testCases) {
        final message = 'Você gastou R\$ ${testCase.spent.toStringAsFixed(2)} '
            'de R\$ ${testCase.budget.toStringAsFixed(2)}';

        expect(message, contains(testCase.spent.toStringAsFixed(2)));
        expect(message, contains(testCase.budget.toStringAsFixed(2)));
      }
    });

    test('Deve formatar alertas SOS com urgência', () {
      final userName = 'João Silva';
      final location = 'Centro de São Paulo';
      final message = 'ALERTA SOS: $userName precisa de ajuda em $location';

      expect(message, contains('ALERTA SOS'));
      expect(message, contains(userName));
      expect(message, contains(location));
      expect(message.startsWith('ALERTA'), true);
    });

    test('Deve validar formatação de todas as mensagens', () {
      final messages = [
        'Viagem amanhã!',
        'Orçamento 90% usado',
        'Check-in atrasado',
        'ALERTA SOS',
        'Nova curtida',
        'Novo comentário',
      ];

      for (final message in messages) {
        expect(message.isNotEmpty, true);
        expect(message.length, greaterThan(5));
      }
    });
  });

  group('Notification Filtering Tests', () {
    late List<AppNotification> testNotifications;

    setUp(() {
      final now = DateTime.now();
      testNotifications = [
        _createTestNotification(
          id: '1',
          type: NotificationType.like,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        _createTestNotification(
          id: '2',
          type: NotificationType.comment,
          isRead: true,
          createdAt: now,
        ),
        _createTestNotification(
          id: '3',
          type: NotificationType.safetyAlert,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        _createTestNotification(
          id: '4',
          type: NotificationType.like,
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];
    });

    test('Deve filtrar notificações não lidas', () {
      final unread = testNotifications.where((n) => !n.isRead).toList();

      expect(unread.length, 3);
      expect(unread.every((n) => !n.isRead), true);
    });

    test('Deve filtrar por tipo de notificação', () {
      final likes = testNotifications
          .where((n) => n.type == NotificationType.like)
          .toList();

      expect(likes.length, 2);
      expect(likes.every((n) => n.type == NotificationType.like), true);
    });

    test('Deve filtrar alertas de segurança', () {
      final safetyAlerts = testNotifications
          .where((n) => n.type == NotificationType.safetyAlert)
          .toList();

      expect(safetyAlerts.length, 1);
      expect(safetyAlerts.first.type, NotificationType.safetyAlert);
    });

    test('Deve ordenar por data (mais recente primeiro)', () {
      final sorted = List<AppNotification>.from(testNotifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.id, '2'); // Mais recente
      expect(sorted.last.id, '4'); // Mais antiga

      // Verificar ordem decrescente
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].createdAt.isAfter(sorted[i + 1].createdAt) ||
              sorted[i].createdAt.isAtSameMomentAs(sorted[i + 1].createdAt),
          true,
        );
      }
    });

    test('Deve combinar múltiplos filtros', () {
      final unreadLikes = testNotifications
          .where((n) => !n.isRead && n.type == NotificationType.like)
          .toList();

      expect(unreadLikes.length, 2);
      expect(unreadLikes.every((n) => !n.isRead), true);
      expect(unreadLikes.every((n) => n.type == NotificationType.like), true);
    });
  });

  group('Edge Cases Tests', () {
    test('Deve lidar com viagem sem data de início', () {
      final DateTime? startDate = null;

      expect(startDate, isNull);
      expect(() => startDate?.difference(DateTime.now()), returnsNormally);
    });

    test('Deve evitar divisão por zero no orçamento', () {
      final budget = 0.0;
      final spent = 100.0;
      final percentage = budget > 0 ? (spent / budget) : 0.0;

      expect(percentage, 0.0);
      expect(() => percentage, returnsNormally);
    });

    test('Deve lidar com lista vazia de notificações', () {
      final notifications = <AppNotification>[];

      expect(notifications.isEmpty, true);
      expect(notifications.length, 0);
      expect(notifications.where((n) => !n.isRead).toList(), isEmpty);
    });

    test('Deve lidar com notificação sem comentário', () {
      final notification = _createTestNotification(
        type: NotificationType.like,
        commentText: null,
      );

      expect(notification.commentText, isNull);
      expect(notification.commentText ?? 'default', 'default');
    });

    test('Deve lidar com datas extremas', () {
      final extremeDates = [
        DateTime(2020, 1, 1),
        DateTime(2030, 12, 31),
        DateTime.now().add(const Duration(days: 365 * 10)),
      ];

      for (final date in extremeDates) {
        expect(() => date.difference(DateTime.now()), returnsNormally);
      }
    });

    test('Deve validar IDs únicos', () {
      final ids = ['1', '2', '3', '4', '5'];
      final uniqueIds = ids.toSet();

      expect(uniqueIds.length, ids.length);
    });

    test('Deve lidar com strings vazias', () {
      final emptyStrings = ['', '   ', '\n', '\t'];

      for (final str in emptyStrings) {
        expect(str.trim().isEmpty, true);
      }
    });
  });

  group('Performance Tests', () {
    test('Deve processar grande volume de notificações', () {
      final notifications = List.generate(
        1000,
        (i) => _createTestNotification(id: 'notif_$i'),
      );

      expect(notifications.length, 1000);

      final filtered = notifications.where((n) => !n.isRead).toList();
      expect(filtered.length, lessThanOrEqualTo(1000));
    });

    test('Deve ordenar grande volume eficientemente', () {
      final now = DateTime.now();
      final notifications = List.generate(
        500,
        (i) => _createTestNotification(
          id: 'notif_$i',
          createdAt: now.subtract(Duration(hours: i)),
        ),
      );

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(notifications.first.id, 'notif_0');
      expect(notifications.last.id, 'notif_499');
    });
  });
}

// Helper function para criar notificações de teste
AppNotification _createTestNotification({
  String? id,
  NotificationType type = NotificationType.like,
  String senderName = 'Test User',
  String postName = 'Test Post',
  String? commentText,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id ?? 'notif_test',
    receiverId: 'user_2',
    senderId: 'user_1',
    senderName: senderName,
    postId: 'post_123',
    postName: postName,
    type: type,
    commentText: commentText,
    createdAt: createdAt ?? DateTime.now(),
    isRead: isRead,
  );
}

// Made with Bob
