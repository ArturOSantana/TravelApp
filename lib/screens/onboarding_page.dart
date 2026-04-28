import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late AnimationController _textAnimationController;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: "Planeje Suas Viagens",
      description:
          "Organize roteiros, atividades e orçamento em um só lugar. Perfeito para viagens solo ou em grupo.",
      icon: Icons.map_outlined,
      color: Colors.deepPurple,
      features: [
        "Crie itinerários detalhados",
        "Gerencie viagens em grupo",
        "Modo nômade para viagens sem data",
      ],
    ),
    OnboardingContent(
      title: "Divida Gastos Facilmente",
      description:
          "Registre despesas e divida automaticamente entre o grupo. Saiba quem deve para quem em tempo real.",
      icon: Icons.payments_outlined,
      color: Colors.green,
      features: [
        "Divisão automática de custos",
        "Múltiplas moedas suportadas",
        "Relatórios financeiros detalhados",
      ],
    ),
    OnboardingContent(
      title: "Guarde Suas Memórias",
      description:
          "Crie um diário de viagem com fotos e compartilhe com amigos e família através de um álbum online.",
      icon: Icons.photo_library_outlined,
      color: Colors.orange,
      features: [
        "Diário com mood tracking",
        "Álbum compartilhável online",
        "Reações e comentários",
      ],
    ),
    OnboardingContent(
      title: "Viaje com Segurança",
      description:
          "Botão de pânico, check-ins de segurança e compartilhamento de localização para sua tranquilidade.",
      icon: Icons.security_outlined,
      color: Colors.red,
      features: [
        "Botão de pânico com GPS",
        "Monitoramento de trajeto",
        "Alertas automáticos",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconAnimationController.reset();
    _textAnimationController.reset();
    _iconAnimationController.forward();
    _textAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Botão Skip com animação
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo ou título
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(-20 * (1 - value), 0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flight_takeoff,
                                  color: _pages[_currentPage].color,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Travel App",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Botão Skip
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: _pages[_currentPage].color,
                      ),
                      child: const Text(
                        "Pular",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo dos slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),

              // Indicador de páginas com animação
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 12,
                    dotWidth: 12,
                    activeDotColor: _pages[_currentPage].color,
                    dotColor: Colors.grey.shade300,
                    expansionFactor: 3,
                  ),
                ),
              ),

              // Botão de ação com animação
              Padding(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage == _pages.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pages[_currentPage].color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? "Começar Agora"
                                      : "Próximo",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.check_circle_outline
                                      : Icons.arrow_forward,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingContent content, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone animado com rotação e escala
          AnimatedBuilder(
            animation: _iconAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconAnimationController.value,
                child: Transform.rotate(
                  angle: (1 - _iconAnimationController.value) * math.pi * 2,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          content.color.withOpacity(0.2),
                          content.color.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: content.color.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      content.icon,
                      size: 80,
                      color: content.color,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 50),

          // Título com animação de fade e slide
          AnimatedBuilder(
            animation: _textAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _textAnimationController.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _textAnimationController.value)),
                  child: Text(
                    content.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: content.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Descrição com animação
          AnimatedBuilder(
            animation: _textAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _textAnimationController.value * 0.8,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _textAnimationController.value)),
                  child: Text(
                    content.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Features com animação escalonada
          ...List.generate(
            content.features.length,
            (featureIndex) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(
                  milliseconds: 400 + (featureIndex * 100),
                ),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: content.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: content.color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                content.features[featureIndex],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}

