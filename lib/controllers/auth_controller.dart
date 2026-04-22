import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      var doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // --- VERIFICAR SE EMAIL EXISTE ---
  Future<bool> isEmailRegistered(String email) async {
    try {
      final query = await _db.collection('users').where('email', isEqualTo: email.trim()).get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; 
    } on FirebaseAuthException catch (e) {
      return 'Erro: ${e.message}';
    } catch (e) {
      return 'Ocorreu um erro inesperado.';
    }
  }

  Future<String?> register(
    String name,
    String email,
    String password, {
    String phone = '',
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        final normalizedName = name.trim();
        await userCredential.user!.updateDisplayName(normalizedName);

        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          name: normalizedName,
          email: email.trim(),
          phone: phone.trim(),
        );

        await _db.collection('users').doc(newUser.uid).set({
          ...newUser.toMap(),
          'name': normalizedName,
          'userName': normalizedName,
          'email': email.trim(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Este e-mail já está cadastrado.';
      if (e.code == 'weak-password') return 'A senha é muito fraca.';
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();
        final data = doc.data();

        final storedName = (data?['name'] ?? data?['userName'] ?? '').toString().trim();
        final authName = user.displayName?.trim() ?? '';
        final normalizedName = storedName.isNotEmpty ? storedName : authName;

        await docRef.set({
          'uid': user.uid,
          'name': normalizedName,
          'userName': normalizedName,
          'email': user.email?.trim() ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } on FirebaseAuthException {
      return 'E-mail ou senha inválidos.';
    }
  }

  Future<UserModel?> getUserData() async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return null;
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<String?> updateUserProfile(UserModel user) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return 'Usuário não autenticado';
      final payload = {
        ...user.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('users').doc(uid).set(payload, SetOptions(merge: true));
      return null;
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
