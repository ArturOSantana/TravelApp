import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<String?> register(String name, String email, String password) async {
    try {

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );


      if (userCredential.user != null) {
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

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
      if (e.code == 'user-not-found') return 'Usuário não encontrado.';
      if (e.code == 'wrong-password') return 'Senha incorreta.';
      return 'E-mail ou senha inválidos.';
    }
  }


  Future<void> logout() async {
    await _auth.signOut();
  }
}