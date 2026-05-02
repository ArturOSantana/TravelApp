import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authController.getUserData();
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _bioController.text = user.bio;
          _emergencyNameController.text = user.emergencyContact;
          _emergencyPhoneController.text = user.emergencyPhone;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao carregar perfil: $e"),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await StorageService.pickImageFromGallery();
    if (file != null) {
      setState(() => _imageFile = file);
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
          content: Text(
              value ? "Modo PREMIUM ativado!" : "Modo PREMIUM desativado."),
          backgroundColor: value ? AppColors.warning : AppColors.textDisabled,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final myPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final emergencyPhone =
          _emergencyPhoneController.text.replaceAll(RegExp(r'\D'), '');

      if (myPhone == emergencyPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("O telefone de emergência não pode ser igual ao seu!"),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        String? photoUrl = _user?.photoUrl;

        if (_imageFile != null) {
          photoUrl = await StorageService.uploadPhoto(
            photo: _imageFile!,
            tripId: 'profiles',
            folder: _user!.uid,
          );
        }

        final updatedUser = _user!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          emergencyContact: _emergencyNameController.text.trim(),
          emergencyPhone: _emergencyPhoneController.text.trim(),
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
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Erro ao salvar: $e"),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    final parts = value.trim().split(' ');
    if (parts.length < 2) return "Informe seu nome completo";
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 11) return "Use o padrão 11999999999";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Meu Perfil")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        actions: [
          if (_isSaving)
            const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_user?.photoUrl != null &&
                                  _user!.photoUrl!.isNotEmpty
                              ? NetworkImage(_user!.photoUrl!)
                              : null) as ImageProvider?,
                      child: (_imageFile == null &&
                              (_user?.photoUrl == null ||
                                  _user!.photoUrl!.isEmpty))
                          ? ClipOval(
                              child: Image.asset(
                                'assets/images/icone_perfil.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 20, color: AppColors.textOnPrimary),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_user?.email ?? '',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: (_user?.isPremium ?? false)
                          ? AppColors.warning
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Usuário Premium",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      "Desbloqueia clima, câmbio e segurança",
                    ),
                    value: _user?.isPremium ?? false,
                    activeColor: AppColors.warning,
                    onChanged: _togglePremium,
                  ),
                ),

                const SizedBox(height: 20),

                // Modo Noturno
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: const ThemeToggleButton(),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: "Nome Completo",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder()),
                  validator: _validateFullName,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: "Telefone",
                      hintText: "11999999999",
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder()),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: "Sobre mim / Bio",
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder()),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const Row(
                  children: [
                    Icon(Icons.emergency, color: AppColors.error),
                    SizedBox(width: 10),
                    Text("Contato de Emergência",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: const InputDecoration(
                      labelText: "Nome do Contato",
                      prefixIcon: Icon(Icons.contact_phone),
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Campo obrigatório" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: "Telefone de Emergência",
                      hintText: "11999999999",
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder()),
                  validator: (v) {
                    final res = _validatePhone(v);
                    if (res != null) return res;
                    if (v == _phoneController.text)
                      return "Não pode ser igual ao seu número";
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _authController.logout();

                      if (mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Sair da Conta"),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
