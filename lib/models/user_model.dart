class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String emergencyPhone;
  final String bio;
  final String? photoUrl;
  final bool isPremium; // Campo para diferenciar usuários

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
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      emergencyPhone: data['emergencyPhone'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      isPremium: data['isPremium'] ?? false,
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
    );
  }
}
