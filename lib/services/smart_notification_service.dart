import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/exceptions/app_exceptions.dart';
import '../models/trip.dart';
import '../models/expense.dart';

/// Serviço de notificações inteligentes e contextuais
///
/// Responsabilidades:
/// - Notificações baseadas em contexto (viagens próximas, orçamento, etc.)
/// - Agendamento de verificações periódicas
/// - Lembretes de check-in de segurança
/// - Notificações de conquistas e dicas
///
/// Integra: flutter_local_notifications + Firebase Firestore
class SmartNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _isInitialized = false;

  // IDs de notificações agendadas
  static const int _upcomingTripsCheckId = 1000;
  static const int _budgetCheckId = 1001;
  static const int _safetyCheckinId = 1002;

  // Constantes de validação
  static const int _minTripNameLength = 2;
  static const int _minUserNameLength = 2;
  static const double _minSavings = 0.01;
  static const double _maxSavings = 999999.99;

  /// Inicializa o serviço de notificações inteligentes
  ///
  /// Agenda verificações periódicas automáticas
  ///
  /// Lança:
  /// - [GenericException]: Se falhar ao inicializar
  static Future<void> initialize() async {
    if (_isInitialized) {
      return; // Já inicializado
    }

    try {
      await _scheduleSmartChecks();
      _isInitialized = true;
    } catch (e) {
      throw GenericException(
        'Falha ao inicializar serviço de notificações inteligentes',
        originalError: e,
      );
    }
  }

  /// Agenda verificações periódicas diárias
  static Future<void> _scheduleSmartChecks() async {
    try {
      // Verificar viagens próximas (diariamente às 9h)
      await _scheduleDaily(
        id: _upcomingTripsCheckId,
        hour: 9,
        minute: 0,
        title: 'Preparação de Viagem',
        body: 'Verificando suas próximas viagens...',
      );

      // Verificar orçamento (diariamente às 20h)
      await _scheduleDaily(
        id: _budgetCheckId,
        hour: 20,
        minute: 0,
        title: 'Controle Financeiro',
        body: 'Analisando seus gastos...',
      );

      // Lembrete de check-in de segurança (diariamente às 12h)
      await _scheduleDaily(
        id: _safetyCheckinId,
        hour: 12,
        minute: 0,
        title: 'Check-in de Segurança',
        body: 'Não esqueça de fazer seu check-in diário',
      );
    } catch (e) {
      throw GenericException(
        'Falha ao agendar verificações periódicas',
        originalError: e,
      );
    }
  }

  /// Agenda notificação diária em horário específico
  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    _validateHour(hour);
    _validateMinute(minute);

    try {
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
    } catch (e) {
      throw GenericException(
        'Falha ao agendar notificação diária',
        originalError: e,
      );
    }
  }

  /// Verifica viagens próximas e envia notificações relevantes
  ///
  /// Chamado automaticamente pelo agendamento diário
  static Future<void> checkUpcomingTrips() async {
    _ensureAuthenticated();

    try {
      final user = _auth.currentUser!;

      final tripsSnapshot = await _db
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'planned')
          .get();

      for (var doc in tripsSnapshot.docs) {
        try {
          final trip = Trip.fromFirestore(doc);

          if (trip.startDate != null) {
            final daysUntil = trip.startDate!.difference(DateTime.now()).inDays;

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
        } catch (e) {
          // Continua mesmo se falhar para uma viagem específica
          continue;
        }
      }
    } catch (e) {
      throw GenericException(
        'Erro ao verificar viagens próximas',
        originalError: e,
      );
    }
  }

  /// Verifica status do orçamento e envia alertas
  ///
  /// Chamado automaticamente pelo agendamento diário
  static Future<void> checkBudgetStatus() async {
    _ensureAuthenticated();

    try {
      final user = _auth.currentUser!;

      final tripsSnapshot = await _db
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in tripsSnapshot.docs) {
        try {
          final trip = Trip.fromFirestore(doc);

          final expensesSnapshot = await _db
              .collection('expenses')
              .where('tripId', isEqualTo: trip.id)
              .get();

          double totalSpent = 0;
          for (var expenseDoc in expensesSnapshot.docs) {
            final expense = Expense.fromFirestore(expenseDoc);
            totalSpent += expense.value;
          }

          final percentageUsed =
              trip.budget > 0 ? (totalSpent / trip.budget) : 0;

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
        } catch (e) {
          // Continua mesmo se falhar para uma viagem específica
          continue;
        }
      }
    } catch (e) {
      throw GenericException(
        'Erro ao verificar orçamento',
        originalError: e,
      );
    }
  }

  /// Lembra usuário de fazer check-in de segurança
  ///
  /// Chamado automaticamente pelo agendamento diário
  static Future<void> remindSafetyCheckin() async {
    _ensureAuthenticated();

    try {
      final user = _auth.currentUser!;

      final tripsSnapshot = await _db
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (tripsSnapshot.docs.isNotEmpty) {
        final trip = Trip.fromFirestore(tripsSnapshot.docs.first);

        // Verificar último check-in
        final checkinsSnapshot = await _db
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
      throw GenericException(
        'Erro ao verificar check-in de segurança',
        originalError: e,
      );
    }
  }

  /// Notifica atividade no diário de viagem
  static Future<void> notifyJournalActivity({
    required String tripName,
    required String userName,
    required String action,
  }) async {
    _validateTripName(tripName);
    _validateUserName(userName);
    _validateAction(action);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Novo no Diário',
      body: '$userName $action em $tripName',
    );
  }

  /// Notifica oportunidade de economia
  static Future<void> notifySavingsOpportunity({
    required String tripName,
    required double potentialSavings,
  }) async {
    _validateTripName(tripName);
    _validateSavings(potentialSavings);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Dica de Economia',
      body:
          'Você pode economizar R\$ ${potentialSavings.toStringAsFixed(2)} em $tripName',
      importance: Importance.high,
    );
  }

  /// Notifica alerta climático
  static Future<void> notifyWeatherAlert({
    required String destination,
    required String alert,
  }) async {
    _validateDestination(destination);
    _validateAlert(alert);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Alerta de Clima',
      body: '$alert em $destination',
      importance: Importance.high,
    );
  }

  /// Notifica documentos pendentes
  static Future<void> notifyDocumentReminder({
    required String tripName,
    required List<String> missingDocuments,
  }) async {
    _validateTripName(tripName);
    _validateDocuments(missingDocuments);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Documentos Pendentes',
      body: 'Não esqueça: ${missingDocuments.join(", ")} para $tripName',
      importance: Importance.high,
    );
  }

  /// Notifica melhor época para viajar
  static Future<void> notifyBestTimeToTravel({
    required String destination,
    required String month,
    required String reason,
  }) async {
    _validateDestination(destination);
    _validateMonth(month);
    _validateReason(reason);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Melhor Época para Viajar',
      body: '$month é ideal para $destination. $reason',
    );
  }

  /// Notifica conquista desbloqueada
  static Future<void> notifyAchievement({
    required String title,
    required String description,
  }) async {
    _validateAchievementTitle(title);
    _validateAchievementDescription(description);

    await _sendNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Conquista Desbloqueada!',
      body: '$title - $description',
      importance: Importance.high,
    );
  }

  /// Cancela todas as notificações agendadas
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw GenericException(
        'Falha ao cancelar todas as notificações',
        originalError: e,
      );
    }
  }

  /// Cancela notificação específica
  static Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      throw GenericException(
        'Falha ao cancelar notificação',
        originalError: e,
      );
    }
  }

  /// Verifica se o serviço está inicializado
  static bool get isInitialized => _isInitialized;

  // ========== MÉTODOS PRIVADOS ==========

  /// Envia notificação genérica
  static Future<void> _sendNotification({
    required int id,
    required String title,
    required String body,
    Importance importance = Importance.defaultImportance,
  }) async {
    try {
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
            priority:
                importance == Importance.max ? Priority.max : Priority.high,
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
    } catch (e) {
      throw GenericException(
        'Falha ao enviar notificação',
        originalError: e,
      );
    }
  }

  // ========== VALIDAÇÕES ==========

  static void _ensureAuthenticated() {
    if (_auth.currentUser == null) {
      throw AuthException('Usuário não autenticado');
    }
  }

  static void _validateHour(int hour) {
    if (hour < 0 || hour > 23) {
      throw ValidationException(
          'Hora inválida: $hour. Deve estar entre 0 e 23');
    }
  }

  static void _validateMinute(int minute) {
    if (minute < 0 || minute > 59) {
      throw ValidationException(
          'Minuto inválido: $minute. Deve estar entre 0 e 59');
    }
  }

  static void _validateTripName(String tripName) {
    if (tripName.trim().isEmpty) {
      throw ValidationException('Nome da viagem não pode estar vazio');
    }
    if (tripName.trim().length < _minTripNameLength) {
      throw ValidationException(
        'Nome da viagem muito curto: ${tripName.length}. Mínimo: $_minTripNameLength',
      );
    }
  }

  static void _validateUserName(String userName) {
    if (userName.trim().isEmpty) {
      throw ValidationException('Nome do usuário não pode estar vazio');
    }
    if (userName.trim().length < _minUserNameLength) {
      throw ValidationException(
        'Nome do usuário muito curto: ${userName.length}. Mínimo: $_minUserNameLength',
      );
    }
  }

  static void _validateAction(String action) {
    if (action.trim().isEmpty) {
      throw ValidationException('Ação não pode estar vazia');
    }
  }

  static void _validateSavings(double savings) {
    if (savings < _minSavings || savings > _maxSavings) {
      throw ValidationException(
        'Valor de economia inválido: $savings. Deve estar entre $_minSavings e $_maxSavings',
      );
    }
  }

  static void _validateDestination(String destination) {
    if (destination.trim().isEmpty) {
      throw ValidationException('Destino não pode estar vazio');
    }
  }

  static void _validateAlert(String alert) {
    if (alert.trim().isEmpty) {
      throw ValidationException('Alerta não pode estar vazio');
    }
  }

  static void _validateDocuments(List<String> documents) {
    if (documents.isEmpty) {
      throw ValidationException('Lista de documentos não pode estar vazia');
    }
  }

  static void _validateMonth(String month) {
    if (month.trim().isEmpty) {
      throw ValidationException('Mês não pode estar vazio');
    }
  }

  static void _validateReason(String reason) {
    if (reason.trim().isEmpty) {
      throw ValidationException('Razão não pode estar vazia');
    }
  }

  static void _validateAchievementTitle(String title) {
    if (title.trim().isEmpty) {
      throw ValidationException('Título da conquista não pode estar vazio');
    }
  }

  static void _validateAchievementDescription(String description) {
    if (description.trim().isEmpty) {
      throw ValidationException('Descrição da conquista não pode estar vazia');
    }
  }
}

// Made with Bob
