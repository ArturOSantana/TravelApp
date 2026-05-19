import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Cria uma nova viagem no Firestore
  ///
  /// LEMBRAR: Validar as datas antes de chamar este método!
  /// A data de início deve ser anterior à data de término
  Future<void> createTrip({
    required String destination,
    required String startDate,
    required String endDate,
  }) async {
    final usuario = auth.currentUser;

    // TODO: Adicionar validação de datas aqui
    // TODO: Verificar se o usuário tem permissão (limite de viagens no plano free)

    await firestore.collection("trips").add({
      "destination": destination,
      "start_date": startDate,
      "end_date": endDate,
      "userId": usuario?.uid,
      "created_at": Timestamp.now(),
    });
  }
}
