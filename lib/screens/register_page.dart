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
              behavior: SnackBarBehavior.floating,
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
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double formWidth = screenWidth > 600 ? 500 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text("Criar Conta"),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            width: formWidth, 
            child: Form(
              key: _formKey,
              child: AutofillGroup( 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: "Ícone de novo usuário",
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 80,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Cadastre-se para começar sua jornada",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // NOME COMPLETO
                    TextFormField(
                      controller: nameController,
                      autofillHints: const [AutofillHints.name], 
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Nome Completo",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Telefone",
                        hintText: "(00) 00000-0000",
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          tooltip: "Mostrar/Ocultar senha", // WCAG Label
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (value) =>
                      value == null || value.length < 6 ? "A senha deve ter pelo menos 6 caracteres" : null,
                    ),
                    const SizedBox(height: 15),

                    // CONFIRMAR SENHA
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: "Confirmar Senha",
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          tooltip: "Mostrar/Ocultar confirmação",
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Confirme sua senha";
                        if (value != passwordController.text) return "As senhas não coincidem";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // BOTÃO CADASTRAR (WCAG: Tamanho mínimo de toque)
                    Semantics(
                      button: true,
                      label: "Finalizar cadastro e criar conta",
                      child: SizedBox(
                        width: double.infinity,
                        height: 56, 
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "Criar Minha Conta",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LINK VOLTAR
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)), 
                      child: const Text("Já tenho uma conta. Fazer Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
