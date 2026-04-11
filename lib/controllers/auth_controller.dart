import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> register(String name, String email, String password, {String phone = ''}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: 'user', // Padrão
        );
        
        await _db.collection('users').doc(newUser.uid).set({
          ...newUser.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Este e-mail já está cadastrado.';
      if (e.code == 'weak-password') return 'A senha é muito fraca.';
      if (e.code == 'invalid-email') return 'O formato do e-mail é inválido.';
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return 'E-mail ou senha inválidos.';
    }
  }

  Future<UserModel?> getUserData() async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return null;
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<String?> updateUserProfile(UserModel user) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return 'Usuário não autenticado';
      
      await _db.collection('users').doc(uid).update(user.toMap());
      return null;
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
