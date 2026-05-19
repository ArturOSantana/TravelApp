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

  Future<bool> isEmailRegistered(String email) async {
    try {
      // Verifica se o email já existe no Firestore
      final consulta = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      return consulta.docs.isNotEmpty;
    } catch (e) {
      // Em caso de erro, assume que o email existe para evitar duplicatas
      return true;
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
      UserCredential credencialUsuario = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credencialUsuario.user != null) {
        final nomeNormalizado = name.trim();
        await credencialUsuario.user!.updateDisplayName(nomeNormalizado);

        UserModel novoUsuario = UserModel(
          uid: credencialUsuario.user!.uid,
          name: nomeNormalizado,
          email: email.trim(),
          phone: phone.trim(),
        );

        // Salva os dados do usuário no Firestore
        // Mantém name e userName sincronizados para evitar inconsistências
        await _db.collection('users').doc(novoUsuario.uid).set({
          ...novoUsuario.toMap(),
          'name': nomeNormalizado,
          'userName': nomeNormalizado,
          'email': email.trim(),
          'phone': phone.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        return 'Este e-mail já está cadastrado.';
      if (e.code == 'weak-password') return 'A senha é muito fraca.';
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final usuario = credencial.user;
      if (usuario != null) {
        final docRef = _db.collection('users').doc(usuario.uid);
        final doc = await docRef.get();
        final dados = doc.data();

        // Sincroniza o nome entre Firestore e Firebase Auth
        final nomeArmazenado =
            (dados?['name'] ?? dados?['userName'] ?? '').toString().trim();
        final nomeAuth = usuario.displayName?.trim() ?? '';
        final nomeNormalizado =
            nomeArmazenado.isNotEmpty ? nomeArmazenado : nomeAuth;

        await docRef.set({
          'uid': usuario.uid,
          'name': nomeNormalizado,
          'userName': nomeNormalizado,
          'email': usuario.email?.trim() ?? '',
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
      await _db
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true));
      return null;
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
