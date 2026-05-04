import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomPackingTemplate {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String iconName;
  final List<CustomTemplateItem> items;
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isPublic;

  CustomPackingTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.iconName,
    required this.items,
    required this.createdAt,
    this.lastModified,
    this.isPublic = false,
  });

  IconData get icon {
    switch (iconName) {
      case 'beach_access':
        return Icons.beach_access;
      case 'terrain':
        return Icons.terrain;
      case 'location_city':
        return Icons.location_city;
      case 'business_center':
        return Icons.business_center;
      case 'nature_people':
        return Icons.nature_people;
      case 'flight':
        return Icons.flight;
      case 'backpack':
        return Icons.backpack;
      case 'luggage':
        return Icons.luggage;
      case 'hiking':
        return Icons.hiking;
      case 'sports':
        return Icons.sports;
      case 'camera':
        return Icons.camera_alt;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.inventory_2;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'iconName': iconName,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified ?? DateTime.now()),
      'isPublic': isPublic,
    };
  }

  factory CustomPackingTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomPackingTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'inventory_2',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => CustomTemplateItem.fromMap(item))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? false,
    );
  }

  CustomPackingTemplate copyWith({
    String? name,
    String? description,
    String? iconName,
    List<CustomTemplateItem>? items,
    bool? isPublic,
  }) {
    return CustomPackingTemplate(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      items: items ?? this.items,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class CustomTemplateItem {
  final String name;
  final String category;

  const CustomTemplateItem({
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
    };
  }

  factory CustomTemplateItem.fromMap(Map<String, dynamic> map) {
    return CustomTemplateItem(
      name: map['name'] ?? '',
      category: map['category'] ?? 'Outros',
    );
  }
}
