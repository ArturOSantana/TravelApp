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

  final AuthController _authController = AuthController();

  bool _isLoading = false;

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
              content: Text("Conta criada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
                  Icons.person_add_alt_1,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Cadastre-se para começar",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nome Completo",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Informe seu nome" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || !value.contains('@') ? "E-mail inválido" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telefone",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Informe seu telefone" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Senha",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Cadastrar",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Já tenho uma conta. Entrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
