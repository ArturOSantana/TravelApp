import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/packing_checklist.dart';
import '../services/packing_checklist_service.dart';

class PackingChecklistController {
  PackingChecklistController({PackingChecklistService? service})
      : _service = service ?? PackingChecklistService();

  final PackingChecklistService _service;

  static const List<String> defaultCategories = [
    'Roupas',
    'Documentos',
    'Eletrônicos',
    'Higiene',
    'Medicamentos',
    'Calçados',
    'Acessórios',
    'Outros',
  ];

  Stream<List<String>> watchTripCategories(String tripId) {
    return FirebaseFirestore.instance
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
      final activityCategories = snapshot.docs
          .map((doc) => _capitalize(doc.data()['category'] ?? 'Geral'))
          .toSet();

      final allCategories = {...defaultCategories, ...activityCategories};
      return ['Todos', ...allCategories.toList()..sort()];
    });
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Stream<PackingChecklistViewData> watchViewData({
    required String tripId,
    required String selectedCategory,
    required bool showOnlyPending,
    required bool showOnlyPriority,
    required String searchQuery,
  }) {
    return _service.watchItems(tripId).map(
          (items) => buildViewData(
            items: items,
            selectedCategory: selectedCategory,
            showOnlyPending: showOnlyPending,
            showOnlyPriority: showOnlyPriority,
            searchQuery: searchQuery,
          ),
        );
  }

  PackingChecklistViewData buildViewData({
    required List<PackingItem> items,
    required String selectedCategory,
    required bool showOnlyPending,
    required bool showOnlyPriority,
    required String searchQuery,
  }) {
    final filteredItems = applyFilters(
      items: items,
      selectedCategory: selectedCategory,
      showOnlyPending: showOnlyPending,
      showOnlyPriority: showOnlyPriority,
      searchQuery: searchQuery,
    );

    final groupedItems = groupByCategory(filteredItems);
    final totalCount = items.length;
    final checkedCount = items.where((item) => item.isChecked).length;
    final pendingCount = totalCount - checkedCount;
    final priorityCount = items.where(isPriority).length;
    final pendingPriorityCount =
        items.where((item) => isPriority(item) && !item.isChecked).length;
    final progress = totalCount == 0 ? 0.0 : checkedCount / totalCount;
    final categoriesCount = groupByCategory(items).length;

    return PackingChecklistViewData(
      allItems: items,
      filteredItems: filteredItems,
      groupedItems: groupedItems,
      totalCount: totalCount,
      checkedCount: checkedCount,
      pendingCount: pendingCount,
      priorityCount: priorityCount,
      pendingPriorityCount: pendingPriorityCount,
      categoriesCount: categoriesCount,
      progress: progress,
    );
  }

  List<PackingItem> applyFilters({
    required List<PackingItem> items,
    required String selectedCategory,
    required bool showOnlyPending,
    required bool showOnlyPriority,
    required String searchQuery,
  }) {
    var filtrados = List<PackingItem>.from(items);
    final buscaNormalizada = searchQuery.toLowerCase().trim();

    // Filtra por categoria selecionada
    if (selectedCategory != 'Todos') {
      filtrados = filtrados
          .where((item) =>
              item.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // Busca por nome, notas ou categoria
    if (buscaNormalizada.isNotEmpty) {
      filtrados = filtrados.where((item) {
        final nome = item.name.toLowerCase();
        final notas = (item.notes ?? '').toLowerCase();
        final categoria = item.category.toLowerCase();

        return nome.contains(buscaNormalizada) ||
            notas.contains(buscaNormalizada) ||
            categoria.contains(buscaNormalizada);
      }).toList();
    }

    // Mostra apenas itens pendentes (não marcados)
    if (showOnlyPending) {
      filtrados = filtrados.where((item) => !item.isChecked).toList();
    }

    // Mostra apenas itens prioritários
    if (showOnlyPriority) {
      filtrados = filtrados.where(isPriority).toList();
    }

    // Ordenação: não marcados primeiro, depois prioridade, depois data de criação
    filtrados.sort((a, b) {
      if (a.isChecked != b.isChecked) {
        return a.isChecked ? 1 : -1;
      }

      final aPrioridade = isPriority(a);
      final bPrioridade = isPriority(b);
      if (aPrioridade != bPrioridade) {
        return aPrioridade ? -1 : 1;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return filtrados;
  }

  Map<String, List<PackingItem>> groupByCategory(List<PackingItem> items) {
    final grouped = <String, List<PackingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  bool isPriority(PackingItem item) {
    return item.isPriority;
  }

  Future<void> addItem({
    required String tripId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool isPriority = false,
  }) {
    return _service.addItem(
      tripId: tripId,
      name: name,
      category: category,
      quantity: quantity,
      notes: notes,
      isPriority: isPriority,
    );
  }

  Future<void> updateItem({
    required String itemId,
    required String name,
    required String category,
    required int quantity,
    String? notes,
    bool? isPriority,
  }) {
    return _service.updateItem(
      itemId: itemId,
      name: name,
      category: category,
      quantity: quantity,
      notes: notes,
      isPriority: isPriority,
    );
  }

  Future<int> addTemplateItems({
    required String tripId,
    required List<Map<String, String>> items,
  }) {
    return _service.addTemplateItems(tripId: tripId, items: items);
  }

  Future<void> toggleItem({required String itemId, required bool isChecked}) {
    return _service.toggleItem(itemId: itemId, isChecked: isChecked);
  }

  Future<void> togglePriority({
    required String itemId,
    required bool isPriority,
  }) {
    return _service.togglePriority(itemId: itemId, isPriority: isPriority);
  }

  Future<void> markAllAsChecked(String tripId) {
    return _service.markAllAsChecked(tripId);
  }

  Future<void> deleteItem(String itemId) {
    return _service.deleteItem(itemId);
  }
}
