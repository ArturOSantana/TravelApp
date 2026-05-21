import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import '../core/exceptions/app_exceptions.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static const int _minNotificationId = 0;
  static const int _maxNotificationId = 2147483647;
  static const int _minTitleLength = 1;
  static const int _maxTitleLength = 65;
  static const int _minBodyLength = 1;
  static const int _maxBodyLength = 240;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _isInitialized = true;
    } catch (e) {
      throw GenericException(
        'Falha ao inicializar serviço de notificações',
        originalError: e,
      );
    }
  }

  static Future<void> _requestAndroidPermissions() async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      // Permissões opcionais
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {}

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    _ensureInitialized();
    _validateNotificationId(id);
    _validateTitle(title);
    _validateBody(body);
    _validateScheduledDate(scheduledDate);

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'travel_channel_v1',
            'Roteiro de Viagem',
            channelDescription: 'Alarmes das atividades do seu roteiro',
            importance: Importance.max,
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
        payload: payload,
      );
    } catch (e) {
      throw GenericException(
        'Falha ao agendar notificação',
        originalError: e,
      );
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _ensureInitialized();
    _validateNotificationId(id);
    _validateTitle(title);
    _validateBody(body);

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'travel_channel_v1',
            'Roteiro de Viagem',
            channelDescription: 'Notificações do aplicativo de viagens',
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
        payload: payload,
      );
    } catch (e) {
      throw GenericException(
        'Falha ao exibir notificação',
        originalError: e,
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    _ensureInitialized();
    _validateNotificationId(id);

    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      throw GenericException(
        'Falha ao cancelar notificação',
        originalError: e,
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    _ensureInitialized();

    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw GenericException(
        'Falha ao cancelar todas as notificações',
        originalError: e,
      );
    }
  }

  /// Retorna lista de notificações pendentes
  ///
  /// Retorna: Lista de notificações agendadas
  ///
  /// Lança:
  /// - [GenericException]: Se falhar ao obter lista
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    _ensureInitialized();

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      throw GenericException(
        'Falha ao obter notificações pendentes',
        originalError: e,
      );
    }
  }

  /// Verifica se o serviço está inicializado
  static bool get isInitialized => _isInitialized;

  // ========== MÉTODOS PRIVADOS DE VALIDAÇÃO ==========

  /// Garante que o serviço foi inicializado
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw GenericException(
        'Serviço de notificações não foi inicializado. Chame NotificationService.init() primeiro',
      );
    }
  }

  /// Valida ID da notificação
  static void _validateNotificationId(int id) {
    if (id < _minNotificationId || id > _maxNotificationId) {
      throw ValidationException(
        'ID de notificação inválido: $id. Deve estar entre $_minNotificationId e $_maxNotificationId',
      );
    }
  }

  /// Valida título da notificação
  static void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ValidationException('Título da notificação não pode estar vazio');
    }

    if (title.trim().length < _minTitleLength) {
      throw ValidationException(
        'Título muito curto: ${title.length} caracteres. Mínimo: $_minTitleLength',
      );
    }

    if (title.length > _maxTitleLength) {
      throw ValidationException(
        'Título muito longo: ${title.length} caracteres. Máximo: $_maxTitleLength',
      );
    }
  }

  /// Valida corpo da notificação
  static void _validateBody(String body) {
    if (body.trim().isEmpty) {
      throw ValidationException('Corpo da notificação não pode estar vazio');
    }

    if (body.trim().length < _minBodyLength) {
      throw ValidationException(
        'Corpo muito curto: ${body.length} caracteres. Mínimo: $_minBodyLength',
      );
    }

    if (body.length > _maxBodyLength) {
      throw ValidationException(
        'Corpo muito longo: ${body.length} caracteres. Máximo: $_maxBodyLength',
      );
    }
  }

  /// Valida data agendada
  static void _validateScheduledDate(DateTime scheduledDate) {
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) {
      throw ValidationException(
        'Data agendada não pode estar no passado: ${scheduledDate.toIso8601String()}',
      );
    }

    // Validar que não está muito longe no futuro (máximo 1 ano)
    final oneYearFromNow = now.add(const Duration(days: 365));
    if (scheduledDate.isAfter(oneYearFromNow)) {
      throw ValidationException(
        'Data agendada muito distante: ${scheduledDate.toIso8601String()}. Máximo: 1 ano no futuro',
      );
    }
  }
}

// Made with Bob
