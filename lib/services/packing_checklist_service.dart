import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';
import '../models/packing_checklist.dart';

class PackingChecklistService {
  PackingChecklistService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // Limites de validação
  static const int _maxItemNameLength = 100;
  static const int _maxCategoryLength = 50;
  static const int _maxNotesLength = 500;
  static const int _maxQuantity = 999;
  static const int _maxBatchSize = 500; // Limite do Firestore

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('packing_items');

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Stream<List<PackingItem>> watchItems(String tripId) {
    _validateTripId(tripId);

    try {
      return _collection
          .where('tripId', isEqualTo: tripId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PackingItem.fromFirestore(doc))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao observar itens da bagagem',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao observar itens',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> addItem({
    required String tripId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool isPriority = false,
  }) async {
    _validateTripId(tripId);
    _validateItemName(name);
    _validateCategory(category);
    _validateQuantity(quantity);
    if (notes != null) _validateNotes(notes);

    final userId = currentUserId;
    if (userId.isEmpty) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      await _collection.add({
        'tripId': tripId,
        'createdBy': userId,
        'name': name.trim(),
        'category': category.trim(),
        'quantity': quantity,
        'isChecked': false,
        'notes': notes?.trim(),
        'isPriority': isPriority,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao adicionar item',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao adicionar item',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> updateItem({
    required String itemId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool? isPriority,
  }) async {
    _validateItemId(itemId);
    _validateItemName(name);
    _validateCategory(category);
    _validateQuantity(quantity);
    if (notes != null) _validateNotes(notes);

    final userId = currentUserId;
    if (userId.isEmpty) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      final data = <String, dynamic>{
        'name': name.trim(),
        'category': category.trim(),
        'quantity': quantity,
        'notes': notes?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPriority != null) {
        data['isPriority'] = isPriority;
      }

      await _collection.doc(itemId).update(data);
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao atualizar item',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao atualizar item',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<int> addTemplateItems({
    required String tripId,
    required List<Map<String, String>> items,
  }) async {
    _validateTripId(tripId);
    _validateTemplateItems(items);

    final userId = currentUserId;
    if (userId.isEmpty) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      // Busca itens existentes para evitar duplicatas
      final existingItems =
          await _collection.where('tripId', isEqualTo: tripId).get();

      // Cria chave única: "nome|categoria" (case-insensitive)
      final existingKeys = existingItems.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final category =
            (data['category'] ?? '').toString().trim().toLowerCase();
        return '$name|$category';
      }).toSet();

      final batch = _db.batch();
      var addedCount = 0;

      for (final item in items) {
        final name = (item['name'] ?? '').trim();
        final category = (item['category'] ?? 'Outros').trim();

        if (name.isEmpty) continue;

        final uniqueKey = '${name.toLowerCase()}|${category.toLowerCase()}';

        // Pula duplicatas
        if (existingKeys.contains(uniqueKey)) continue;

        final docRef = _collection.doc();
        batch.set(docRef, {
          'tripId': tripId,
          'createdBy': userId,
          'name': name,
          'category': category,
          'quantity': 1,
          'isChecked': false,
          'notes': null,
          'isPriority': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        existingKeys.add(uniqueKey);
        addedCount++;
      }

      if (addedCount > 0) {
        await batch.commit();
      }

      return addedCount;
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao adicionar itens do template',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao adicionar template',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> toggleItem({
    required String itemId,
    required bool isChecked,
  }) async {
    _validateItemId(itemId);

    try {
      await _collection.doc(itemId).update({
        'isChecked': isChecked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao marcar item',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao marcar item',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> togglePriority({
    required String itemId,
    required bool isPriority,
  }) async {
    _validateItemId(itemId);

    try {
      await _collection.doc(itemId).update({
        'isPriority': isPriority,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao alterar prioridade',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao alterar prioridade',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> markAllAsChecked(String tripId) async {
    _validateTripId(tripId);

    try {
      final snapshot =
          await _collection.where('tripId', isEqualTo: tripId).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isChecked': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao marcar todos os itens',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao marcar todos',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  Future<void> deleteItem(String itemId) async {
    _validateItemId(itemId);

    try {
      await _collection.doc(itemId).delete();
    } on ValidationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao deletar item',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao deletar item',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  static void _validateTripId(String tripId) {
    if (tripId.trim().isEmpty) {
      throw ValidationException('ID da viagem não pode estar vazio');
    }
    if (tripId.trim().length < 10) {
      throw ValidationException('ID da viagem inválido');
    }
  }

  static void _validateItemId(String itemId) {
    if (itemId.trim().isEmpty) {
      throw ValidationException('ID do item não pode estar vazio');
    }
    if (itemId.trim().length < 10) {
      throw ValidationException('ID do item inválido');
    }
  }

  static void _validateItemName(String name) {
    if (name.trim().isEmpty) {
      throw ValidationException('Nome do item não pode estar vazio');
    }
    if (name.trim().length > _maxItemNameLength) {
      throw ValidationException(
        'Nome do item muito longo (máx. $_maxItemNameLength caracteres)',
      );
    }
  }

  static void _validateCategory(String category) {
    if (category.trim().isEmpty) {
      throw ValidationException('Categoria não pode estar vazia');
    }
    if (category.trim().length > _maxCategoryLength) {
      throw ValidationException(
        'Categoria muito longa (máx. $_maxCategoryLength caracteres)',
      );
    }
  }

  static void _validateQuantity(int quantity) {
    if (quantity < 1) {
      throw ValidationException('Quantidade deve ser no mínimo 1');
    }
    if (quantity > _maxQuantity) {
      throw ValidationException('Quantidade muito alta (máx. $_maxQuantity)');
    }
  }

  static void _validateNotes(String notes) {
    if (notes.length > _maxNotesLength) {
      throw ValidationException(
        'Observações muito longas (máx. $_maxNotesLength caracteres)',
      );
    }
  }

  static void _validateTemplateItems(List<Map<String, String>> items) {
    if (items.isEmpty) {
      throw ValidationException('Lista de itens do template está vazia');
    }
    if (items.length > _maxBatchSize) {
      throw ValidationException(
        'Muitos itens no template (máx. $_maxBatchSize)',
      );
    }
  }
}
