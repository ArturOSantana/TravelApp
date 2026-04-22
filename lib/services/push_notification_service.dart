import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Este canal é usado para notificações importantes do app.',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _sosChannel = AndroidNotificationChannel(
    'sos_alerts',
    'Alertas de Segurança (SOS)',
    description: 'Canal crítico para alertas de emergência.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.createNotificationChannel(_sosChannel);

      await _configureLocalNotifications();
      await _saveDeviceToken();
      _configureMessageHandlers();
    }
  }

  static Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print('🔔 Notificação local clicada: ${details.payload}');
      },
    );
  }

  static Future<void> _saveDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      final user = _auth.currentUser;
      if (token != null && user != null) {
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'platform': Platform.operatingSystem,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erro ao salvar token FCM: $e');
    }
  }

  static void _configureMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
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
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Usuário clicou na notificação');
    });
  }

  static Future<void> _sendInstantNotification({
    required String title, 
    required String body, 
    bool isCritical = false
  }) async {
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
        interruptionLevel: isCritical ? InterruptionLevel.critical : InterruptionLevel.active,
      ),
    );
    
    await _localNotifications.show(
      id: DateTime.now().millisecond, 
      title: title, 
      body: body, 
      notificationDetails: details,
    );
  }

  static Future<void> notifySafetyAlert(String userName, String location) async {
    await _sendInstantNotification(
      title: '🆘 ALERTA DE EMERGÊNCIA!',
      body: '$userName precisa de ajuda em $location',
      isCritical: true,
    );
  }

  static Future<void> notifyNewComment(String postName, String userName) async {
    await _sendInstantNotification(
      title: 'Novo Comentário',
      body: '$userName comentou no seu post "$postName"',
    );
  }

  static Future<void> notifyNewLike(String postName, String userName) async {
    await _sendInstantNotification(
      title: 'Nova Curtida',
      body: '$userName curtiu sua recomendação "$postName"',
    );
  }
}
