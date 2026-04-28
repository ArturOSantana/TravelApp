import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import '../models/user_subscription.dart';
import '../services/subscription_service.dart';

class WelcomePremiumPage extends StatefulWidget {
  const WelcomePremiumPage({super.key});

  @override
  State<WelcomePremiumPage> createState() => _WelcomePremiumPageState();
}

class _WelcomePremiumPageState extends State<WelcomePremiumPage> {
  final PageController _pageController = PageController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  int _currentPage = 0;
  bool _isLoading = false;

  final List<WelcomeContent> _pages = [
    WelcomeContent(
      title: "Bem-vindo ao Travel App!",
      description:
          "O aplicativo completo para planejar e gerenciar suas viagens",
      icon: Icons.flight_takeoff,
      color: Colors.deepPurple,
      features: [
        "Organize roteiros e atividades",
        "Divida gastos automaticamente",
        "Guarde memórias em um diário",
        "Viaje com segurança",
      ],
    ),
    WelcomeContent(
      title: "Comece Gratuitamente",
      description: "Experimente o Travel App sem compromisso",
      icon: Icons.check_circle_outline,
      color: Colors.green,
      features: [
        "✅ Até 3 viagens simultâneas",
        "✅ Até 5 membros por grupo",
        "✅ Todas as funcionalidades básicas",
        "✅ Sem cartão de crédito necessário",
      ],
    ),
    WelcomeContent(
      title: "Desbloqueie Todo o Potencial",
      description: "Upgrade para Premium e tenha acesso ilimitado",
      icon: Icons.workspace_premium,
      color: Colors.deepPurple,
      features: [
        "🚀 Viagens ilimitadas",
        "👥 Até 20 membros por grupo",
        "🤖 Insights avançados com IA",
        "📊 Exportação de relatórios PDF",
        "☁️ Backup automático na nuvem",
        "🚫 Sem anúncios",
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              // Header com logo
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      color: _pages[_currentPage].color,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Travel App",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo dos slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),

              // Indicador de páginas
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

              // Botões de ação
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_currentPage == _pages.length - 1) ...[
                      // Última página - mostrar opções
                      _buildPremiumButton(),
                      const SizedBox(height: 12),
                      _buildFreeButton(),
                    ] else ...[
                      // Outras páginas - botão próximo
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Próximo",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _startWithFree(),
                        child: const Text(
                          "Pular e começar grátis",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(WelcomeContent content, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 140,
                  height: 140,
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
                    size: 70,
                    color: content.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Título
          Text(
            content.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: content.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Descrição
          Text(
            content.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Features
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: content.features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (index == 2) ...[
                        // Última página - usar emojis
                        Text(
                          feature.substring(0, 2),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.substring(3),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Outras páginas - usar ícone de check
                        Icon(
                          Icons.check_circle,
                          color: content.color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _upgradeToPremium(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium),
                  const SizedBox(width: 12),
                  Text(
                    "Começar com Premium - ${_currencyFormat.format(9.90)}/mês",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFreeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _startWithFree(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          side: const BorderSide(color: Colors.deepPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Começar Grátis",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _upgradeToPremium() async {
    setState(() => _isLoading = true);

    try {
      // Simular processamento
      await Future.delayed(const Duration(seconds: 2));

      await SubscriptionService.upgradeToPremium();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text("Bem-vindo ao Premium! 🎉"),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startWithFree() async {
    // Apenas navegar para home - usuário já tem plano free por padrão
    Navigator.pushReplacementNamed(context, '/home');
  }
}

class WelcomeContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  WelcomeContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}

// Made with Bob
