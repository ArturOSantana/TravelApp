import '../core/validators/model_validators.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String emergencyPhone;
  final String bio;
  final String? photoUrl;
  final bool isPremium;
  final List<String> savedPosts;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.emergencyContact = '',
    this.emergencyPhone = '',
    this.bio = '',
    this.photoUrl,
    this.isPremium = false,
    this.savedPosts = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    _validate();
  }

  UserModel._internal({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.bio,
    this.photoUrl,
    required this.isPremium,
    required this.savedPosts,
    required this.createdAt,
    this.updatedAt,
  });

  void _validate() {
    ModelValidators.validateNonEmpty(uid, 'UID');
    ModelValidators.validateNonEmpty(name, 'Nome');
    ModelValidators.validateEmail(email);
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel._internal(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      emergencyPhone: data['emergencyPhone'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      isPremium: data['isPremium'] ?? false,
      savedPosts: data['savedPosts'] != null
          ? List<String>.from(data['savedPosts'])
          : [],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'bio': bio,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'savedPosts': savedPosts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? emergencyPhone,
    String? bio,
    String? photoUrl,
    bool? isPremium,
    List<String>? savedPosts,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      savedPosts: savedPosts ?? this.savedPosts,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ name.hashCode ^ email.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, email: $email)';
}
