import 'package:flutter/material.dart';
import 'register_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentImageIndex = 0;
  //codigo pa animacao de fade entre as imagens
  final List<String> _images = [
    'assets/images/imagi03.jpg',
    'assets/images/imagi04.jpg',
    'assets/images/imagi05.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // 3 seconds per image
      vsync: this,
    );

    // transicao  (0-0.4) → pra (0.4-0.6) → fade tlgd  (0.6-1.0)
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // joga pro lado (starts at -1,0)
    _slideAnimation = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // vai po proximo
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _images.length;
        });
        _animationController.forward(from: 0); // reinicia a animacao para a proxima imagem
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Planner"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            
              const SizedBox(height: 20),
              Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        _images[_currentImageIndex],
                        width: 400,
                        height: 400,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 18),

              const Text(
                "Login",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 30),

              TextField( 
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,  
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardPage(),
                      ),
                    );

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff1eec0),  
                    foregroundColor: Colors.deepPurple, 
                  ),
                  child: const Text("Entrar"),
                ),
              ),

              const SizedBox(height: 15),
            //socorro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                ),
                child: const Text("Criar conta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}