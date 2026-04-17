import 'package:cloud_firestore/cloud_firestore.dart';

class PackingItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final bool isChecked;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;
  final bool isPriority;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.isChecked = false,
    this.notes,
    required this.createdAt,
    this.createdBy,
    this.isPriority = false,
  });

  PackingItem copyWith({
    String? name,
    String? category,
    int? quantity,
    bool? isChecked,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    bool? isPriority,
  }) {
    return PackingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isPriority: isPriority ?? this.isPriority,
    );
  }

  Map<String, dynamic> toMap({
    String? tripId,
    String? userId,
    String? createdBy,
  }) {
    return {
      'tripId': tripId,
      'userId': userId,
      'createdBy': createdBy ?? userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': isChecked,
      'notes': notes,
      'isPriority': isPriority,
      'createdAt': Timestamp.fromDate(createdAt),
    }..removeWhere((key, value) => value == null);
  }

  factory PackingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PackingItem(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? 'Outros').toString(),
      quantity: (data['quantity'] ?? 1) as int,
      isChecked: data['isChecked'] ?? false,
      notes: data['notes']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy']?.toString(),
      isPriority: data['isPriority'] ?? false,
    );
  }
}

class PackingChecklistViewData {
  final List<PackingItem> allItems;
  final List<PackingItem> filteredItems;
  final Map<String, List<PackingItem>> groupedItems;
  final int totalCount;
  final int checkedCount;
  final int pendingCount;
  final int priorityCount;
  final int pendingPriorityCount;
  final int categoriesCount;
  final double progress;

  const PackingChecklistViewData({
    required this.allItems,
    required this.filteredItems,
    required this.groupedItems,
    required this.totalCount,
    required this.checkedCount,
    required this.pendingCount,
    required this.priorityCount,
    required this.pendingPriorityCount,
    required this.categoriesCount,
    required this.progress,
  });

  factory PackingChecklistViewData.empty() {
    return const PackingChecklistViewData(
      allItems: [],
      filteredItems: [],
      groupedItems: {},
      totalCount: 0,
      checkedCount: 0,
      pendingCount: 0,
      priorityCount: 0,
      pendingPriorityCount: 0,
      categoriesCount: 0,
      progress: 0,
    );
  }
}

class PackingChecklist {
  final String id;
  final String tripId;
  final String userId;
  final List<PackingItem> items;
  final DateTime createdAt;
  final DateTime? lastModified;

  PackingChecklist({
    required this.id,
    required this.tripId,
    required this.userId,
    this.items = const [],
    required this.createdAt,
    this.lastModified,
  });

  double get progress {
    if (items.isEmpty) return 0.0;
    final checkedCount = items.where((item) => item.isChecked).length;
    return checkedCount / items.length;
  }

  int get checkedItemsCount => items.where((item) => item.isChecked).length;

  int get totalItemsCount => items.length;

  int get pendingItemsCount => items.where((item) => !item.isChecked).length;

  bool get isComplete =>
      items.isNotEmpty && items.every((item) => item.isChecked);

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified ?? DateTime.now()),
    };
  }

  factory PackingChecklist.fromFirestore(
    DocumentSnapshot doc, {
    List<PackingItem> items = const [],
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PackingChecklist(
      id: doc.id,
      tripId: (data['tripId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      items: items,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
    );
  }
}
