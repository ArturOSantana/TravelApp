import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_subscription.dart';
import '../services/subscription_service.dart';

class PremiumUpgradePage extends StatefulWidget {
  const PremiumUpgradePage({super.key});

  @override
  State<PremiumUpgradePage> createState() => _PremiumUpgradePageState();
}

class _PremiumUpgradePageState extends State<PremiumUpgradePage> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  SubscriptionTier _selectedTier = SubscriptionTier.premium;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Upgrade para Premium",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com ícone
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple[700]!, Colors.deepPurple[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Desbloqueie Todo o Potencial",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Viagens ilimitadas, relatórios PDF e muito mais!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Planos
            _buildPlanCard(SubscriptionTier.free),
            const SizedBox(height: 16),
            _buildPlanCard(SubscriptionTier.premium),

            const SizedBox(height: 30),

            // Comparação de features
            _buildComparisonSection(),

            const SizedBox(height: 30),

            // Botão de upgrade
            if (_selectedTier != SubscriptionTier.free) _buildUpgradeButton(),

            const SizedBox(height: 20),

            // Termos
            Text(
              "Ao continuar, você concorda com nossos Termos de Serviço e Política de Privacidade. "
              "A assinatura será renovada automaticamente.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionTier tier) {
    final planInfo = _getPlanInfo(tier);
    final isSelected = _selectedTier == tier;
    final isFree = tier == SubscriptionTier.free;

    Color cardColor;
    Color accentColor;

    switch (tier) {
      case SubscriptionTier.free:
        cardColor = Colors.grey[100]!;
        accentColor = Colors.grey[700]!;
        break;
      case SubscriptionTier.premium:
        cardColor = Colors.deepPurple[50]!;
        accentColor = Colors.deepPurple;
        break;
      case SubscriptionTier.business:
        cardColor = Colors.blue[50]!;
        accentColor = Colors.blue[900]!;
        break;
    }

    return GestureDetector(
      onTap: isFree ? null : () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPlanIcon(tier),
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planInfo['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        if (!isFree)
                          Text(
                            "${_currencyFormat.format(planInfo['price'])}/mês",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isSelected && !isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Selecionado",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...List<Widget>.from(
              (planInfo['features'] as List<String>).map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlanIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person_outline;
      case SubscriptionTier.premium:
        return Icons.workspace_premium;
      case SubscriptionTier.business:
        return Icons.business_center;
    }
  }

  Widget _buildComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Por que fazer upgrade?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonItem(
            "Viagens Ilimitadas",
            "Free: 3 viagens",
            "Premium: Ilimitadas",
            Icons.map,
            Colors.blue,
          ),
          _buildComparisonItem(
            "Membros por Grupo",
            "Free: 3 membros",
            "Premium: Ilimitados",
            Icons.group,
            Colors.green,
          ),
          _buildComparisonItem(
            "Fotos por Viagem",
            "Free: 10 fotos",
            "Premium: Ilimitadas",
            Icons.photo_library,
            Colors.purple,
          ),
          _buildComparisonItem(
            "Exportar Relatórios",
            "Free: Não disponível",
            "Premium: PDF completo",
            Icons.picture_as_pdf,
            Colors.red,
          ),
          _buildComparisonItem(
            "Suporte Prioritário",
            "Free: Padrão",
            "Premium: Prioritário",
            Icons.support_agent,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    String title,
    String freeText,
    String premiumText,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  freeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  premiumText,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    final planInfo = _getPlanInfo(_selectedTier);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedTier == SubscriptionTier.premium
              ? Colors.deepPurple
              : Colors.blue[900],
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
                  const Icon(Icons.rocket_launch),
                  const SizedBox(width: 12),
                  Text(
                    "Assinar ${planInfo['name']} - ${_currencyFormat.format(planInfo['price'])}/mês",
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

  Map<String, dynamic> _getPlanInfo(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return {
          'name': 'Free',
          'price': 0.0,
          'features': [
            'Até 3 viagens',
            'Até 3 membros por viagem',
            'Funcionalidades básicas',
          ],
        };
      case SubscriptionTier.premium:
        return {
          'name': 'Premium',
          'price': 9.90,
          'features': [
            'Viagens ilimitadas',
            'Membros ilimitados por grupo',
            'Fotos ilimitadas',
            'Exportar relatórios em PDF',
            'Sem anúncios',
            'Suporte prioritário',
          ],
        };
      case SubscriptionTier.business:
        return {
          'name': 'Business',
          'price': 9.90,
          'features': [
            'Tudo do Premium',
          ],
        };
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    try {
      // Simular processamento de pagamento
      await Future.delayed(const Duration(seconds: 2));

      // Atualiza para Premium (usa UserModel.isPremium)
      await SubscriptionService.upgradeToPremium();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Parabéns! Você agora é ${_selectedTier == SubscriptionTier.premium ? 'Premium' : 'Business'}!",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao processar pagamento: $e"),
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
}

