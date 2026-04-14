import 'package:cloud_firestore/cloud_firestore.dart';


class PackingItem {
  final String id;
  final String name;
  final String
  category; 
  final int quantity;
  final bool isChecked;
  final String? notes;
  final DateTime createdAt;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.isChecked = false,
    this.notes,
    required this.createdAt,
  });

  PackingItem copyWith({
    String? name,
    String? category,
    int? quantity,
    bool? isChecked,
    String? notes,
  }) {
    return PackingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': isChecked,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory PackingItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return PackingItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Outros',
      quantity: data['quantity'] ?? 1,
      isChecked: data['isChecked'] ?? false,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Checklist completo de bagagem para uma viagem
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

  /// Retorna o progresso do checklist (0.0 a 1.0)
  double get progress {
    if (items.isEmpty) return 0.0;
    final checkedCount = items.where((item) => item.isChecked).length;
    return checkedCount / items.length;
  }

  /// Retorna quantos itens estão marcados
  int get checkedItemsCount => items.where((item) => item.isChecked).length;

  /// Retorna total de itens
  int get totalItemsCount => items.length;

  /// Verifica se o checklist está completo
  bool get isComplete =>
      items.isNotEmpty && items.every((item) => item.isChecked);

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'createdAt': createdAt,
      'lastModified': lastModified ?? DateTime.now(),
    };
  }

  factory PackingChecklist.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return PackingChecklist(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
    );
  }
}

/// Templates pré-definidos de checklist por tipo de viagem
class PackingTemplate {
  static List<Map<String, String>> getBeachTemplate() {
    return [
      {'name': 'Protetor solar', 'category': 'Higiene'},
      {'name': 'Óculos de sol', 'category': 'Acessórios'},
      {'name': 'Chinelo', 'category': 'Calçados'},
      {'name': 'Maiô/Sunga', 'category': 'Roupas'},
      {'name': 'Canga/Toalha de praia', 'category': 'Roupas'},
      {'name': 'Boné/Chapéu', 'category': 'Acessórios'},
      {'name': 'Roupa leve', 'category': 'Roupas'},
      {'name': 'Sandália', 'category': 'Calçados'},
    ];
  }

  static List<Map<String, String>> getMountainTemplate() {
    return [
      {'name': 'Jaqueta impermeável', 'category': 'Roupas'},
      {'name': 'Bota de trilha', 'category': 'Calçados'},
      {'name': 'Mochila', 'category': 'Acessórios'},
      {'name': 'Garrafa térmica', 'category': 'Outros'},
      {'name': 'Lanterna', 'category': 'Eletrônicos'},
      {'name': 'Roupa térmica', 'category': 'Roupas'},
      {'name': 'Luvas', 'category': 'Roupas'},
      {'name': 'Gorro', 'category': 'Acessórios'},
    ];
  }

  static List<Map<String, String>> getCityTemplate() {
    return [
      {'name': 'Tênis confortável', 'category': 'Calçados'},
      {'name': 'Mochila/Bolsa', 'category': 'Acessórios'},
      {'name': 'Carregador portátil', 'category': 'Eletrônicos'},
      {'name': 'Guarda-chuva', 'category': 'Acessórios'},
      {'name': 'Roupa casual', 'category': 'Roupas'},
      {'name': 'Documentos', 'category': 'Documentos'},
      {'name': 'Cartão de crédito', 'category': 'Documentos'},
      {'name': 'Câmera/Celular', 'category': 'Eletrônicos'},
    ];
  }

  static List<Map<String, String>> getEssentialsTemplate() {
    return [
      {'name': 'Passaporte/RG', 'category': 'Documentos'},
      {'name': 'Cartão de crédito', 'category': 'Documentos'},
      {'name': 'Dinheiro', 'category': 'Documentos'},
      {'name': 'Celular', 'category': 'Eletrônicos'},
      {'name': 'Carregador', 'category': 'Eletrônicos'},
      {'name': 'Escova de dentes', 'category': 'Higiene'},
      {'name': 'Pasta de dente', 'category': 'Higiene'},
      {'name': 'Medicamentos', 'category': 'Medicamentos'},
      {'name': 'Roupa íntima', 'category': 'Roupas'},
      {'name': 'Meias', 'category': 'Roupas'},
    ];
  }
}

// Made with Bob
