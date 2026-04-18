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
    return _service
        .watchItems(tripId)
        .map(
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
    final pendingPriorityCount = items
        .where((item) => isPriority(item) && !item.isChecked)
        .length;
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
    var filtered = List<PackingItem>.from(items);
    final normalizedQuery = searchQuery.toLowerCase().trim();

    if (selectedCategory != 'Todos') {
      filtered = filtered
          .where((item) => item.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.name.toLowerCase();
        final notes = (item.notes ?? '').toLowerCase();
        final category = item.category.toLowerCase();

        return name.contains(normalizedQuery) ||
            notes.contains(normalizedQuery) ||
            category.contains(normalizedQuery);
      }).toList();
    }

    if (showOnlyPending) {
      filtered = filtered.where((item) => !item.isChecked).toList();
    }

    if (showOnlyPriority) {
      filtered = filtered.where(isPriority).toList();
    }

    filtered.sort((a, b) {
      if (a.isChecked != b.isChecked) {
        return a.isChecked ? 1 : -1;
      }

      final aPriority = isPriority(a);
      final bPriority = isPriority(b);
      if (aPriority != bPriority) {
        return aPriority ? -1 : 1;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
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
