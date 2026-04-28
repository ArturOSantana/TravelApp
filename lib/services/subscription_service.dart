import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> _isPremiumUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final userData = UserModel.fromMap(doc.data()!);
      return userData.isPremium;
    } catch (e) {
      print('[ERROR] Erro ao verificar Premium: $e');
      return false;
    }
  }

  static Future<bool> canCreateTrip() async {
    print('[LOCK] Verificando limite de viagens...');

    final isPremium = await _isPremiumUser();
    if (isPremium) {
      print('[PREMIUM] Usuário Premium - viagens ilimitadas');
      return true;
    }

    // Contar viagens do usuário Free
    final user = _auth.currentUser;
    if (user == null) return false;

    final tripsSnapshot = await _db
        .collection('trips')
        .where('members', arrayContains: user.uid)
        .get();

    final currentCount = tripsSnapshot.docs.length;
    const maxTrips = 3; // Limite Free

    print('[STATS] Viagens: $currentCount/$maxTrips');
    return currentCount < maxTrips;
  }

  static Future<bool> canAddMember(String tripId) async {
    print('[LOCK] Verificando limite de membros...');

    final isPremium = await _isPremiumUser();
    if (isPremium) {
      print('[PREMIUM] Usuário Premium - membros ilimitados');
      return true;
    }

    final tripDoc = await _db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) return false;

    final members = List<String>.from(tripDoc.data()?['members'] ?? []);
    const maxMembers = 3; // Limite Free

    print('[STATS] Membros: ${members.length}/$maxMembers');
    return members.length < maxMembers;
  }

  /// Verifica se tem acesso a insights avançados (análises com IA)
  static Future<bool> hasAdvancedInsights() async {
    print('[LOCK] Verificando acesso a Insights Avançados...');
    final isPremium = await _isPremiumUser();
    print(isPremium
        ? '[PREMIUM] Premium - Insights liberados'
        : '[FREE] Free - Insights bloqueados');
    return isPremium;
  }

  /// Verifica se tem acesso a features de IA
  static Future<bool> hasAIFeatures() async {
    return await _isPremiumUser();
  }

  /// Verifica se pode exportar relatórios
  static Future<bool> canExportReports() async {
    return await _isPremiumUser();
  }

  /// Atualiza para Premium (usa o campo isPremium do UserModel)
  static Future<void> upgradeToPremium() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _db.collection('users').doc(user.uid).update({
      'isPremium': true,
    });

    print('[OK] Usuário atualizado para Premium!');
  }

  /// Downgrade para Free
  static Future<void> downgradeToFree() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _db.collection('users').doc(user.uid).update({
      'isPremium': false,
    });

    print('[INFO] Usuário voltou para Free');
  }
}
