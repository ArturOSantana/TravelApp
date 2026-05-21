import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../theme/travel_colors.dart';
import '../theme/travel_spacing.dart';
import '../theme/travel_text_styles.dart';
import '../widgets/core/travel_widgets.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
              backgroundColor: TravelColors.error,
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
        title: Semantics(
          header: true,
          child: Text(
            "Recuperar Senha",
            style: TravelTextStyles.headlineSmall(context),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TravelSpacing.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Insira seu e-mail abaixo e enviaremos um link de recuperação se a conta existir.",
              style: TravelTextStyles.bodyMedium(context),
            ),
            SizedBox(height: TravelSpacing.lg),
            TravelTextField.email(
              controller: resetEmailController,
              label: "E-mail cadastrado",
            ),
          ],
        ),
        actions: [
          TravelButton.text(
            label: "Cancelar",
            onPressed: () => Navigator.pop(context),
            semanticLabel: "Cancelar recuperação de senha",
          ),
          TravelButton.primary(
            label: "Enviar Link",
            semanticLabel: "Enviar link de recuperação de senha",
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Semantics(
                      liveRegion: true,
                      child: const Text("Enviando link de recuperação..."),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );

                final String? error =
                    await _authController.resetPassword(email);

                if (mounted) {
                  if (error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Semantics(
                          liveRegion: true,
                          child: const Text(
                            "Se este e-mail estiver cadastrado, você receberá um link de recuperação. Verifique sua caixa de entrada e a pasta de SPAM.",
                          ),
                        ),
                        backgroundColor: TravelColors.success,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Semantics(
                          liveRegion: true,
                          child: Text(error),
                        ),
                        backgroundColor: TravelColors.error,
                      ),
                    );
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double formWidth = screenWidth > 600 ? 450 : screenWidth;
    final bool isMobile = TravelSpacing.isMobile(screenWidth);

    return Scaffold(
      backgroundColor: TravelColors.cloudWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TravelColors.skyBlueLight.withOpacity(0.1),
              TravelColors.cloudWhite,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile ? TravelSpacing.lg : TravelSpacing.xl,
            ),
            child: Container(
              width: formWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo com animação sutil
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: EdgeInsets.all(TravelSpacing.md),
                        decoration: BoxDecoration(
                          color: TravelColors.cloudWhiteLight,
                          shape: BoxShape.circle,
                          boxShadow: TravelColors.softShadow,
                        ),
                        child: Semantics(
                          label: "Logo do aplicativo Travel Planner",
                          image: true,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: TravelSpacing.xl),

                    // Título personalizado (não "Bem-vindo" genérico)
                    Semantics(
                      header: true,
                      child: Text(
                        "Suas viagens começam aqui",
                        style: TravelTextStyles.displaySmall(context),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: TravelSpacing.sm),

                    Text(
                      "Entre para planejar sua próxima aventura",
                      style: TravelTextStyles.bodyMedium(context).copyWith(
                        color: TravelColors.stoneGray,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: TravelSpacing.xxl),

                    // Campo de E-mail usando TravelTextField
                    TravelTextField.email(
                      controller: emailController,
                      semanticLabel: "Campo de e-mail para login",
                    ),

                    SizedBox(height: TravelSpacing.md),

                    // Campo de Senha usando TravelTextField
                    TravelTextField.password(
                      controller: passwordController,
                      onSubmitted: (_) => _handleLogin(),
                      semanticLabel: "Campo de senha para login",
                    ),

                    // Link "Esqueci minha senha"
                    Align(
                      alignment: Alignment.centerRight,
                      child: TravelButton.text(
                        label: "Esqueci minha senha",
                        onPressed: _showForgotPasswordDialog,
                        semanticLabel: "Recuperar senha esquecida",
                      ),
                    ),

                    SizedBox(height: TravelSpacing.xl),

                    // Botão Entrar usando TravelButton
                    TravelButton.primary(
                      label: "Entrar",
                      onPressed: _isLoading ? null : _handleLogin,
                      size: TravelButtonSize.large,
                      isLoading: _isLoading,
                      fullWidth: true,
                      icon: Icons.login,
                      semanticLabel: "Fazer login na sua conta",
                    ),

                    SizedBox(height: TravelSpacing.lg),

                    // Divider com texto
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: TravelColors.stoneGrayLight,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: TravelSpacing.md,
                          ),
                          child: Text(
                            "ou",
                            style: TravelTextStyles.labelSmall(context),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: TravelColors.stoneGrayLight,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: TravelSpacing.lg),

                    // Link para cadastro
                    Semantics(
                      label: "Não tem uma conta? Cadastre-se",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Primeira vez aqui?",
                            style: TravelTextStyles.bodyMedium(context),
                          ),
                          SizedBox(width: TravelSpacing.xs),
                          TravelButton.text(
                            label: "Criar conta",
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
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
      ),
    );
  }
}

// Made with Bob
