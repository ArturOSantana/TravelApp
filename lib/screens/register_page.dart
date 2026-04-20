import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String? erro = await _authController.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        phone: phoneController.text.trim(),
      );

      if (mounted) setState(() => _isLoading = false);

      if (erro == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Conta criada com sucesso! ✨"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volta para o login
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Conta"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Cadastre-se para começar sua jornada",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // NOME
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nome Completo",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Informe seu nome";
                    if (value.trim().split(' ').length < 2) return "Informe nome e sobrenome";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // E-MAIL
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Informe seu e-mail";
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return "E-mail inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // TELEFONE
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefone",
                    hintText: "(00) 00000-0000",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Informe seu telefone";
                    if (value.replaceAll(RegExp(r'\D'), '').length < 10) return "Telefone muito curto";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // SENHA
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.length < 6 ? "A senha deve ter pelo menos 6 caracteres" : null,
                ),
                const SizedBox(height: 15),

                // CONFIRMAR SENHA
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirmar Senha",
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Confirme sua senha";
                    if (value != passwordController.text) return "As senhas não coincidem";
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // BOTÃO CADASTRAR
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Criar Conta",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Já tenho uma conta. Fazer Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
