import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/exceptions/app_exceptions.dart';


class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _isInitialized = false;

  // Canais de notificação
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Este canal é usado para notificações importantes do app.',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _sosChannel =
      AndroidNotificationChannel(
    'sos_alerts',
    'Alertas de Segurança (SOS)',
    description: 'Canal crítico para alertas de emergência.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // Constantes de validação
  static const int _minTitleLength = 1;
  static const int _maxTitleLength = 65;
  static const int _minBodyLength = 1;
  static const int _maxBodyLength = 240;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return; // Já inicializado
    }

    if (kIsWeb) {
      return; // Push notifications não suportadas na web
    }

    try {
      // Solicitar permissões
      final settings = await _requestPermissions();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Configurar canais de notificação (Android)
        await _setupNotificationChannels();

        // Configurar notificações locais
        await _configureLocalNotifications();

        // Salvar token do dispositivo
        await _saveDeviceToken();

        _configureMessageHandlers();

        _isInitialized = true;
      } else {
        throw PermissionException(
          'Permissão de notificações negada pelo usuário',
        );
      }
    } catch (e) {
      if (e is PermissionException) {
        rethrow;
      }
      throw GenericException(
        'Falha ao inicializar serviço de push notifications',
        originalError: e,
      );
    }
  }

  static Future<NotificationSettings> _requestPermissions() async {
    try {
      return await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );
    } catch (e) {
      throw PermissionException(
        'Falha ao solicitar permissões de notificação',
      );
    }
  }

  static Future<void> _setupNotificationChannels() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.createNotificationChannel(_sosChannel);
      }
    } catch (e) {
      throw GenericException(
        'Falha ao configurar canais de notificação',
        originalError: e,
      );
    }
  }

  static Future<void> _configureLocalNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } catch (e) {
      throw GenericException(
        'Falha ao configurar notificações locais',
        originalError: e,
      );
    }
  }

  static void _onNotificationTapped(NotificationResponse details) {
    // Aqui pode adicionar navegação baseada no payload
  }

  static Future<void> _saveDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      final user = _auth.currentUser;

      if (token == null) {
        throw GenericException('Não foi possível obter token FCM');
      }

      if (user == null) {
        throw AuthException('Usuário não autenticado');
      }

      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'platform': Platform.operatingSystem,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw GenericException(
        'Falha ao salvar token FCM',
        originalError: e,
      );
    }
  }

  static void _configureMessageHandlers() {
    // Mensagens recebidas quando app está em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensagens que abriram o app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      try {
        await _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      } catch (e) {
        // Não lançar exceção, apenas logar
        // A notificação push ainda foi recebida
      }
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Aqui pode adicionar navegação baseada nos dados da mensagem
  }

  static Future<void> sendInstantNotification({
    required String title,
    required String body,
    bool isCritical = false,
  }) async {
    _ensureInitialized();
    _validateTitle(title);
    _validateBody(body);

    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          isCritical ? _sosChannel.id : 'system_alerts',
          isCritical ? _sosChannel.name : 'Alertas do Sistema',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: isCritical,
          category: isCritical ? AndroidNotificationCategory.alarm : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: isCritical
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      );

      await _localNotifications.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      throw GenericException(
        'Falha ao enviar notificação instantânea',
        originalError: e,
      );
    }
  }

  static Future<void> notifySafetyAlert(
    String userName,
    String location,
  ) async {
    _validateUserName(userName);
    _validateLocation(location);

    await sendInstantNotification(
      title: 'ALERTA DE EMERGÊNCIA!',
      body: '$userName precisa de ajuda em $location',
      isCritical: true,
    );
  }

  static Future<void> notifyNewComment(
    String postName,
    String userName,
    String receiverId,
  ) async {
    _ensureInitialized();
    _validatePostName(postName);
    _validateUserName(userName);
    _validateUserId(receiverId);

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw AuthException('Usuário não autenticado');
    }

    // Não notificar o próprio usuário
    if (currentUser.uid == receiverId) {
      return;
    }

    await sendInstantNotification(
      title: 'Novo Comentário',
      body: '$userName comentou no seu post "$postName"',
    );
  }

  static Future<void> notifyNewLike(
    String postName,
    String userName,
    String receiverId,
  ) async {
    _ensureInitialized();
    _validatePostName(postName);
    _validateUserName(userName);
    _validateUserId(receiverId);

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw AuthException('Usuário não autenticado');
    }

    // Não notificar o próprio usuário
    if (currentUser.uid == receiverId) {
      return;
    }

    await sendInstantNotification(
      title: 'Nova Curtida',
      body: '$userName curtiu sua recomendação "$postName"',
    );
  }

  static Future<void> refreshToken() async {
    _ensureInitialized();
    await _saveDeviceToken();
  }

  static bool get isInitialized => _isInitialized;

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw GenericException(
        'Serviço de push notifications não foi inicializado. Chame PushNotificationService.initialize() primeiro',
      );
    }
  }

  static void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ValidationException('Título não pode estar vazio');
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

  static void _validateBody(String body) {
    if (body.trim().isEmpty) {
      throw ValidationException('Corpo não pode estar vazio');
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

  static void _validateUserName(String userName) {
    if (userName.trim().isEmpty) {
      throw ValidationException('Nome de usuário não pode estar vazio');
    }

    if (userName.trim().length < 2) {
      throw ValidationException(
        'Nome de usuário muito curto: ${userName.length} caracteres. Mínimo: 2',
      );
    }
  }

  static void _validateLocation(String location) {
    if (location.trim().isEmpty) {
      throw ValidationException('Localização não pode estar vazia');
    }

    if (location.trim().length < 3) {
      throw ValidationException(
        'Localização muito curta: ${location.length} caracteres. Mínimo: 3',
      );
    }
  }

  static void _validatePostName(String postName) {
    if (postName.trim().isEmpty) {
      throw ValidationException('Nome do post não pode estar vazio');
    }
  }

  static void _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ValidationException('ID do usuário não pode estar vazio');
    }
  }
}

// Made with Bob
