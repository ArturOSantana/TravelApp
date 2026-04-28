import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/trip.dart';
import '../models/expense.dart';
import '../controllers/trip_controller.dart';

/// Envia notificações contextuais baseadas no comportamento do usuário
class SmartNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final TripController _tripController = TripController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    // Agendar verificações periódicas
    await _scheduleSmartChecks();
  }

  static Future<void> _scheduleSmartChecks() async {
    // Verificar viagens próximas (diariamente às 9h)
    await _scheduleDaily(
      id: 1000,
      hour: 9,
      minute: 0,
      title: 'Preparação de Viagem',
      body: 'Verificando suas próximas viagens...',
      callback: _checkUpcomingTrips,
    );

    // Verificar orçamento (diariamente às 20h)
    await _scheduleDaily(
      id: 1001,
      hour: 20,
      minute: 0,
      title: 'Controle Financeiro',
      body: 'Analisando seus gastos...',
      callback: _checkBudgetStatus,
    );

    // Lembrete de check-in de segurança (para viagens ativas)
    await _scheduleDaily(
      id: 1002,
      hour: 12,
      minute: 0,
      title: 'Check-in de Segurança',
      body: 'Não esqueça de fazer seu check-in diário',
      callback: _remindSafetyCheckin,
    );
  }

  /// Agenda notificação diária
  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required Function callback,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_notifications',
          'Notificações Inteligentes',
          channelDescription: 'Notificações contextuais baseadas em IA',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Verifica viagens próximas e envia notificações relevantes
  static Future<void> _checkUpcomingTrips() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'planned')
          .get();

      for (var doc in tripsSnapshot.docs) {
        final trip = Trip.fromFirestore(doc);

        if (trip.startDate != null) {
          final daysUntil = trip.startDate!.difference(DateTime.now()).inDays;

          // Notificações baseadas em proximidade da viagem
          if (daysUntil == 1) {
            await _sendNotification(
              id: trip.id.hashCode,
              title: 'Viagem Amanhã!',
              body:
                  'Sua viagem para ${trip.destination} começa amanhã. Já fez as malas?',
              importance: Importance.max,
            );
          } else if (daysUntil == 7) {
            await _sendNotification(
              id: trip.id.hashCode + 1,
              title: 'Viagem em 1 Semana',
              body:
                  '${trip.destination} está chegando! Hora de finalizar os preparativos.',
            );
          } else if (daysUntil == 30) {
            await _sendNotification(
              id: trip.id.hashCode + 2,
              title: 'Viagem em 1 Mês',
              body:
                  'Comece a planejar sua viagem para ${trip.destination}. Já reservou hospedagem?',
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar viagens próximas: $e');
    }
  }

  /// Verifica status do orçamento e envia alertas
  static Future<void> _checkBudgetStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in tripsSnapshot.docs) {
        final trip = Trip.fromFirestore(doc);

        // Buscar despesas da viagem
        final expensesSnapshot = await FirebaseFirestore.instance
            .collection('expenses')
            .where('tripId', isEqualTo: trip.id)
            .get();

        double totalSpent = 0;
        for (var expenseDoc in expensesSnapshot.docs) {
          final expense = Expense.fromFirestore(expenseDoc);
          totalSpent += expense.value;
        }

        final percentageUsed = trip.budget > 0 ? (totalSpent / trip.budget) : 0;

        // Alertas baseados em porcentagem do orçamento
        if (percentageUsed >= 1.0) {
          await _sendNotification(
            id: trip.id.hashCode + 100,
            title: 'Orçamento Ultrapassado!',
            body:
                'Você gastou R\$ ${totalSpent.toStringAsFixed(2)} de R\$ ${trip.budget.toStringAsFixed(2)} em ${trip.destination}',
            importance: Importance.max,
          );
        } else if (percentageUsed >= 0.9) {
          await _sendNotification(
            id: trip.id.hashCode + 101,
            title: '90% do Orçamento Usado',
            body:
                'Atenção! Você já gastou 90% do orçamento em ${trip.destination}',
            importance: Importance.high,
          );
        } else if (percentageUsed >= 0.75) {
          await _sendNotification(
            id: trip.id.hashCode + 102,
            title: '75% do Orçamento Usado',
            body:
                'Você está usando bem seu orçamento em ${trip.destination}. Continue assim!',
          );
        } else if (percentageUsed >= 0.5) {
          await _sendNotification(
            id: trip.id.hashCode + 103,
            title: 'Metade do Orçamento',
            body:
                'Você gastou 50% do orçamento em ${trip.destination}. Está no caminho certo!',
          );
        }
      }
    } catch (e) {
      print('Erro ao verificar orçamento: $e');
    }
  }

  /// Lembra usuário de fazer check-in de segurança
  static Future<void> _remindSafetyCheckin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (tripsSnapshot.docs.isNotEmpty) {
        final trip = Trip.fromFirestore(tripsSnapshot.docs.first);

        // Verificar último check-in
        final checkinsSnapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc(trip.id)
            .collection('safety_checkins')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (checkinsSnapshot.docs.isEmpty) {
          await _sendNotification(
            id: 2000,
            title: 'Check-in de Segurança',
            body:
                'Faça seu check-in diário para manter seus contatos informados',
            importance: Importance.high,
          );
        } else {
          final lastCheckin =
              checkinsSnapshot.docs.first.data()['timestamp'] as Timestamp;
          final hoursSinceLastCheckin =
              DateTime.now().difference(lastCheckin.toDate()).inHours;

          if (hoursSinceLastCheckin >= 24) {
            await _sendNotification(
              id: 2001,
              title: 'Lembrete de Segurança',
              body:
                  'Faz mais de 24h desde seu último check-in. Seus contatos estão preocupados!',
              importance: Importance.max,
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar check-in de segurança: $e');
    }
  }

  /// Notifica sobre nova atividade no diário
  static Future<void> notifyJournalActivity({
    required String tripName,
    required String userName,
    required String action,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Novo no Diário',
      body: '$userName $action em $tripName',
    );
  }

  /// Notifica sobre economia potencial
  static Future<void> notifySavingsOpportunity({
    required String tripName,
    required double potentialSavings,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Dica de Economia',
      body:
          'Você pode economizar R\$ ${potentialSavings.toStringAsFixed(2)} em $tripName',
      importance: Importance.high,
    );
  }

  /// Notifica sobre clima no destino
  static Future<void> notifyWeatherAlert({
    required String destination,
    required String alert,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Alerta de Clima',
      body: '$alert em $destination',
      importance: Importance.high,
    );
  }

  /// Notifica sobre documentos pendentes
  static Future<void> notifyDocumentReminder({
    required String tripName,
    required List<String> missingDocuments,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Documentos Pendentes',
      body: 'Não esqueça: ${missingDocuments.join(", ")} para $tripName',
      importance: Importance.high,
    );
  }

  /// Notifica sobre melhor época para viajar
  static Future<void> notifyBestTimeToTravel({
    required String destination,
    required String month,
    required String reason,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Melhor Época para Viajar',
      body: '$month é ideal para $destination. $reason',
    );
  }

  /// Notifica sobre conquistas
  static Future<void> notifyAchievement({
    required String title,
    required String description,
  }) async {
    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Conquista Desbloqueada!',
      body: '$title - $description',
      importance: Importance.high,
    );
  }

  /// Envia notificação genérica
  static Future<void> _sendNotification({
    required int id,
    required String title,
    required String body,
    Importance importance = Importance.defaultImportance,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_notifications',
          'Notificações Inteligentes',
          channelDescription: 'Notificações contextuais baseadas em IA',
          importance: importance,
          priority: importance == Importance.max ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: importance == Importance.max
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      ),
    );
  }

  /// Cancela todas as notificações agendadas
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancela notificação específica
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }
}

