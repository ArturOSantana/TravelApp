class UserModel {
  final String uid;
  final String name;
  final String email;
  final String emergencyContact; // Novo: Nome do contato de emergência
  final String emergencyPhone;   // Novo: WhatsApp/Telefone para SOS

  UserModel({
    required this.uid, 
    required this.name, 
    required this.email,
    this.emergencyContact = '',
    this.emergencyPhone = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      emergencyPhone: data['emergencyPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
    };
  }
}
