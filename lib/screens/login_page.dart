import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/accessible_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String? error = await _authController.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (mounted) setState(() => _isLoading = false);

      if (error == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Semantics(liveRegion: true, child: Text(error)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(
      text: emailController.text,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(header: true, child: const Text("Recuperar Senha")),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Insira seu e-mail abaixo. Verificaremos se você tem uma conta e enviaremos o link.",
              style: AppTextStyles.bodySmall(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail cadastrado",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          AccessibleButton(
            label: "Cancelar",
            onPressed: () => Navigator.pop(context),
            type: ButtonType.text,
            semanticLabel: "Cancelar recuperação de senha",
          ),
          AccessibleButton(
            label: "Verificar e Enviar",
            type: ButtonType.primary,
            semanticLabel: "Verificar e-mail e enviar link de recuperação",
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Semantics(
                      liveRegion: true,
                      child: const Text("Verificando cadastro..."),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );

                final bool exists = await _authController.isEmailRegistered(
                  email,
                );

                if (mounted) {
                  if (!exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Semantics(
                          liveRegion: true,
                          child: const Text(
                            "Este e-mail não está cadastrado em nossa base. ",
                          ),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } else {
                    final String? error = await _authController.resetPassword(
                      email,
                    );
                    if (mounted) {
                      if (error == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Semantics(
                              liveRegion: true,
                              child: const Text(
                                "Link enviado! Verifique seu e-mail (e a pasta de SPAM). ",
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Semantics(
                              liveRegion: true,
                              child: Text(error),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double formWidth = screenWidth > 600 ? 450 : screenWidth;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Container(
            width: formWidth,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: "Logo do aplicativo Travel Planner",
                    image: true,
                    child: Container(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text("Bem-vindo", style: AppTextStyles.h1(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Acesse sua conta para continuar",
                    style: AppTextStyles.bodySmall(context),
                  ),
                  const SizedBox(height: 48),

                  // E-MAIL
                  Semantics(
                    textField: true,
                    label: "Campo de e-mail",
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.body(context),
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        labelStyle: AppTextStyles.body(
                          context,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Informe seu e-mail"
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SENHA
                  Semantics(
                    textField: true,
                    label: "Campo de senha",
                    obscured: _obscurePassword,
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      style: AppTextStyles.body(context),
                      decoration: InputDecoration(
                        labelText: "Senha",
                        labelStyle: AppTextStyles.body(
                          context,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                        ),
                        suffixIcon: AccessibleIconButton(
                          icon: _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          tooltip: _obscurePassword
                              ? "Mostrar senha"
                              : "Ocultar senha",
                          semanticLabel: _obscurePassword
                              ? "Mostrar senha digitada"
                              : "Ocultar senha digitada",
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Informe sua senha"
                          : null,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: AccessibleButton(
                      label: "Esqueci minha senha",
                      onPressed: _showForgotPasswordDialog,
                      type: ButtonType.text,
                      semanticLabel: "Recuperar senha esquecida",
                    ),
                  ),

                  const SizedBox(height: 32),

                  // BOTÃO ENTRAR
                  SizedBox(
                    width: double.infinity,
                    child: AccessibleButton(
                      label: "Entrar",
                      onPressed: _isLoading ? null : _handleLogin,
                      type: ButtonType.primary,
                      size: ButtonSize.large,
                      isLoading: _isLoading,
                      semanticLabel: "Fazer login na sua conta",
                    ),
                  ),

                  const SizedBox(height: 24),

                  Semantics(
                    label: "Não tem uma conta? Cadastre-se",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Não tem uma conta?",
                          style: AppTextStyles.body(context),
                        ),
                        AccessibleButton(
                          label: "Cadastre-se",
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          type: ButtonType.text,
                          semanticLabel: "Ir para página de cadastro",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
