import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authController.getUserData();
    if (user != null) {
      setState(() {
        _user = user;
        _nameController = TextEditingController(text: user.name);
        _phoneController = TextEditingController(text: user.phone);
        _bioController = TextEditingController(text: user.bio);
        _emergencyNameController = TextEditingController(text: user.emergencyContact);
        _emergencyPhoneController = TextEditingController(text: user.emergencyPhone);
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePremium(bool value) async {
    if (_user == null) return;
    setState(() => _isSaving = true);
    final updated = _user!.copyWith(isPremium: value);
    await _authController.updateUserProfile(updated);
    await _loadUserData();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? "Modo PREMIUM ativado! ⭐" : "Modo PREMIUM desativado."),
          backgroundColor: value ? Colors.amber[800] : Colors.grey[800],
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return _user?.photoUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('$uid.jpg');
      
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Erro ao fazer upload da imagem: $e");
      return _user?.photoUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      String? photoUrl = _user?.photoUrl;
      if (_imageFile != null && !kIsWeb) {
        photoUrl = await _uploadImage(_user!.uid);
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        bio: _bioController.text,
        emergencyContact: _emergencyNameController.text,
        emergencyPhone: _emergencyPhoneController.text,
        photoUrl: photoUrl,
      );

      final error = await _authController.updateUserProfile(updatedUser);

      if (mounted) {
        setState(() => _isSaving = false);
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!')),
          );
          _loadUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty
                            ? NetworkImage(_user!.photoUrl!) as ImageProvider
                            : null),
                    child: (_imageFile == null && (_user?.photoUrl == null || _user!.photoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _user?.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // SEÇÃO PARA ALTERAR PREMIUM (PARA TESTES)
              Container(
                decoration: BoxDecoration(
                  color: (_user?.isPremium ?? false) ? Colors.amber[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: (_user?.isPremium ?? false) ? Colors.amber[300]! : Colors.grey[300]!),
                ),
                child: SwitchListTile(
                  title: const Text("Usuário Premium ⭐", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Desbloqueia clima, câmbio e segurança"),
                  value: _user?.isPremium ?? false,
                  activeColor: Colors.amber[800],
                  onChanged: _togglePremium,
                ),
              ),

              const SizedBox(height: 30),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nome Completo",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Telefone",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Sobre mim / Bio",
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(),
              const Row(
                children: [
                  Icon(Icons.emergency, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    "Contato de Emergência",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: "Nome do Contato",
                  prefixIcon: Icon(Icons.contact_phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                  labelText: "Telefone de Emergência",
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _authController.logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Sair da Conta"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
