import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/packing_checklist.dart';

class PackingChecklistService {
  PackingChecklistService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('packing_items');

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Stream<List<PackingItem>> watchItems(String tripId) {
    return _collection
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PackingItem.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addItem({
    required String tripId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool isPriority = false,
  }) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    await _collection.add({
      'tripId': tripId,
      'createdBy': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': false,
      'notes': notes,
      'isPriority': isPriority,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem({
    required String itemId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool? isPriority,
  }) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    final data = <String, dynamic>{
      'name': name,
      'category': category,
      'quantity': quantity,
      'notes': notes,
    };

    if (isPriority != null) {
      data['isPriority'] = isPriority;
    }

    await _collection.doc(itemId).update(data);
  }

  Future<int> addTemplateItems({
    required String tripId,
    required List<Map<String, String>> items,
  }) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    // Busca itens já existentes para evitar duplicatas
    final itensExistentes =
        await _collection.where('tripId', isEqualTo: tripId).get();

    // Cria chave única no formato "nome|categoria" para detectar duplicatas
    final chavesExistentes = itensExistentes.docs.map((doc) {
      final dados = doc.data();
      return '${(dados['name'] ?? '').toString().trim().toLowerCase()}|${(dados['category'] ?? '').toString().trim().toLowerCase()}';
    }).toSet();

    // Usa batch para adicionar múltiplos itens de uma vez (mais eficiente)
    final batch = _db.batch();
    var quantidadeAdicionada = 0;

    for (final item in items) {
      final nome = (item['name'] ?? '').trim();
      final categoria = (item['category'] ?? 'Outros').trim();
      final chaveUnica = '${nome.toLowerCase()}|${categoria.toLowerCase()}';

      // Pula se o nome estiver vazio ou se já existir
      if (nome.isEmpty || chavesExistentes.contains(chaveUnica)) {
        continue;
      }

      final docRef = _collection.doc();
      batch.set(docRef, {
        'tripId': tripId,
        'createdBy': userId,
        'name': nome,
        'category': categoria,
        'quantity': 1,
        'isChecked': false,
        'notes': null,
        'isPriority': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      chavesExistentes.add(chaveUnica);
      quantidadeAdicionada++;
    }

    if (quantidadeAdicionada > 0) {
      await batch.commit();
    }

    return quantidadeAdicionada;
  }

  Future<void> toggleItem({
    required String itemId,
    required bool isChecked,
  }) async {
    await _collection.doc(itemId).update({'isChecked': isChecked});
  }

  Future<void> togglePriority({
    required String itemId,
    required bool isPriority,
  }) async {
    await _collection.doc(itemId).update({'isPriority': isPriority});
  }

  Future<void> markAllAsChecked(String tripId) async {
    final snapshot = await _collection.where('tripId', isEqualTo: tripId).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isChecked': true});
    }
    await batch.commit();
  }

  Future<void> deleteItem(String itemId) async {
    await _collection.doc(itemId).delete();
  }
}
