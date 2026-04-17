import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/packing_checklist.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print(' Permissão de notificações concedida');

      await _configureLocalNotifications();

      await _saveDeviceToken();

      // Configurar handlers
      _configureMessageHandlers();

      // Agendar notificações inteligentes
      await _scheduleSmartNotifications();
    }
  }

  // Configurar notificações locais
  static Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static Future<void> _saveDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      final uid = _auth.currentUser?.uid;

      if (token != null && uid != null) {
        await _db.collection('users').doc(uid).update({
          'fcmToken': token,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ Token FCM salvo: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Erro ao salvar token: $e');
    }
  }

  // Configurar handlers de mensagens
  static void _configureMessageHandlers() {
    // Mensagem recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'Mensagem recebida em foreground: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // Mensagem clicada quando app estava em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notificação clicada (background): ${message.data}');
      _handleNotificationNavigation(message.data);
    });

    // Verificar se app foi aberto por uma notificação
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App aberto por notificação: ${message.data}');
        _handleNotificationNavigation(message.data);
      }
    });
  }

  // Mostrar notificação local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'travel_app_channel',
      'Travel App Notifications',
      channelDescription: 'Notificações do Travel App',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Travel App',
      body: message.notification?.body ?? '',
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print(' Notificação clicada: ${response.payload}');
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    // final id = data['id']; // Comentado para evitar erro de variável não usada

    switch (type) {
      case 'trip_update':
        break;
      case 'expense_added':
        break;
      case 'safety_alert':
        break;
      case 'checklist_reminder':
        // Navegar para a página de checklist
        break;
    }
  }

  static Future<void> _scheduleSmartNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Buscar viagens ativas do usuário
    final tripsSnapshot = await _db
        .collection('trips')
        .where('members', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .get();

    for (var tripDoc in tripsSnapshot.docs) {
      final tripData = tripDoc.data();
      final tripId = tripDoc.id;

      await _scheduleSecurityCheckIn(tripId, tripData['destination']);
      await _checkBudgetAlert(tripId, tripData);
      await _checkActivityChecklist(tripId);
    }
  }

  static Future<void> _scheduleSecurityCheckIn(
    String tripId,
    String destination,
  ) async {
    print('Agendando check-in de segurança para $destination');
  }

  static Future<void> _checkBudgetAlert(
    String tripId,
    Map<String, dynamic> tripData,
  ) async {
    final budget = (tripData['budget'] ?? 0).toDouble();

    final expensesSnapshot = await _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .get();

    double totalSpent = 0;
    for (var doc in expensesSnapshot.docs) {
      totalSpent += (doc.data()['value'] ?? 0).toDouble();
    }

    final percentage = budget > 0 ? (totalSpent / budget) : 0;

    if (percentage >= 0.8 && percentage < 1.0) {
      await _sendBudgetAlert(
        tripId,
        tripData['destination'],
        percentage.toDouble(),
      );
    } else if (percentage >= 1.0) {
      await _sendBudgetExceededAlert(
        tripId,
        tripData['destination'],
        totalSpent - budget,
      );
    }
  }

  static Future<void> _checkActivityChecklist(String tripId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Buscar atividades de hoje
    final activitiesSnapshot = await _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .get();

    List<String> neededCategories = [];
    String activityTitles = '';

    for (var doc in activitiesSnapshot.docs) {
      final data = doc.data();
      final time = (data['time'] as Timestamp).toDate();
      if (time.year == today.year &&
          time.month == today.month &&
          time.day == today.day) {
        neededCategories.add(data['category'] ?? 'general');
        activityTitles += (activityTitles.isEmpty ? '' : ', ') + data['title'];
      }
    }

    if (neededCategories.isEmpty) return;

    // 2. Buscar itens pendentes no checklist
    final checklistSnapshot = await _db
        .collection('packing_items')
        .where('tripId', isEqualTo: tripId)
        .where('isChecked', isEqualTo: false)
        .get();

    List<String> pendingItems = [];
    for (var doc in checklistSnapshot.docs) {
      final item = PackingItem.fromFirestore(doc);
      // Se a categoria do item pendente bate com a categoria de uma atividade de hoje
      if (neededCategories.contains(item.category.toLowerCase()) || 
          item.isPriority) {
        pendingItems.add(item.name);
      }
    }

    // 3. Notificar se houver itens pendentes para as atividades de hoje
    if (pendingItems.isNotEmpty) {
      await _showLocalNotification(
        RemoteMessage(
          notification: RemoteNotification(
            title: '🎒 Itens para hoje!',
            body: 'Você tem atividades (${activityTitles}). Não esqueça: ${pendingItems.take(3).join(", ")}${pendingItems.length > 3 ? " e mais..." : ""}',
          ),
          data: {'type': 'checklist_reminder', 'tripId': tripId},
        ),
      );
    }
  }

  static Future<void> _sendBudgetAlert(
    String tripId,
    String destination,
    double percentage,
  ) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: '⚠️ Atenção ao Orçamento',
          body:
              'Você já gastou ${(percentage * 100).toStringAsFixed(0)}% do orçamento em $destination',
        ),
        data: {'type': 'budget_alert', 'tripId': tripId},
      ),
    );
  }

  static Future<void> _sendBudgetExceededAlert(
    String tripId,
    String destination,
    double exceeded,
  ) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: '🚨 Orçamento Ultrapassado',
          body:
              'Você excedeu o orçamento em R\$ ${exceeded.toStringAsFixed(2)} em $destination',
        ),
        data: {'type': 'budget_exceeded', 'tripId': tripId},
      ),
    );
  }

  static Future<void> sendActivityNotification(
    String tripId,
    String activityName,
  ) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: '📅 Nova Atividade Adicionada',
          body: activityName,
        ),
        data: {'type': 'activity_added', 'tripId': tripId},
      ),
    );
  }

  static Future<void> sendExpenseNotification(
    String tripId,
    String expenseName,
    double value,
  ) async {
    await _showLocalNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: '💸 Nova Despesa Registrada',
          body: '$expenseName - R\$ ${value.toStringAsFixed(2)}',
        ),
        data: {'type': 'expense_added', 'tripId': tripId},
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(' Mensagem recebida em background: ${message.notification?.title}');
}
