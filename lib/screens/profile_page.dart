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

  Future<void> _changeRole(String newRole) async {
    if (_user == null) return;
    setState(() => _isSaving = true);
    final updated = _user!.copyWith(role: newRole);
    await _authController.updateUserProfile(updated);
    await _loadUserData();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Perfil alterado para: ${newRole.toUpperCase()}"), backgroundColor: Colors.blue),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        bio: _bioController.text,
        emergencyContact: _emergencyNameController.text,
        emergencyPhone: _emergencyPhoneController.text,
      );
      await _authController.updateUserProfile(updatedUser);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        actions: [
          if (_isSaving) const Center(child: CircularProgressIndicator())
          else IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(radius: 50, child: const Icon(Icons.person, size: 50)),
              const SizedBox(height: 20),
              
              // SEÇÃO DE TESTE DE ROLES (PARA O TCC)
              const Text("TESTE DE DISTRIBUIÇÃO (ROLE)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roleButton("USER", 'user', Colors.grey),
                  _roleButton("PREMIUM", 'premium', Colors.amber),
                  _roleButton("BUSINESS", 'business', Colors.blue),
                ],
              ),
              const Divider(height: 40),

              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Telefone", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextFormField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder())),
              
              const SizedBox(height: 30),
              const Text("Emergência", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(controller: _emergencyNameController, decoration: const InputDecoration(labelText: "Nome Contato")),
              TextFormField(controller: _emergencyPhoneController, decoration: const InputDecoration(labelText: "Telefone SOS")),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await _authController.logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text("Sair da Conta", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String label, String role, Color color) {
    bool isSelected = _user?.role == role;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
        selected: isSelected,
        onSelected: (val) => _changeRole(role),
        selectedColor: color,
      ),
    );
  }
}
