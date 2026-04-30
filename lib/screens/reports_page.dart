import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../services/subscription_service.dart';
import '../services/pdf_export_service.dart';
import '../services/social_share_service.dart';
import '../services/exchangerate_service.dart';
import 'premium_upgrade_page.dart';

class ReportsPage extends StatefulWidget {
  final Trip trip;
  final List<Expense> expenses;

  const ReportsPage({
    Key? key,
    required this.trip,
    required this.expenses,
  }) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  bool _isExporting = false;
  bool _isSharing = false;

  double get _totalSpent {
    return widget.expenses.fold(0.0, (sum, expense) => sum + expense.value);
  }

  int get _photosCount {
    // Aqui você pode buscar do PhotoGallery se necessário
    return 0;
  }

  Future<void> _exportPDF() async {
    final hasPremium = await SubscriptionService.hasAdvancedInsights();

    if (!hasPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final pdf = await PdfExportService.exportTripReport(
        trip: widget.trip,
        expenses: widget.expenses,
      );

      await PdfExportService.shareReport(pdf, widget.trip.destination);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório PDF exportado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareToSocial() async {
    final hasPremium = await SubscriptionService.hasAdvancedInsights();

    if (!hasPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() => _isSharing = true);

    try {
      await SocialShareService.shareTripCard(
        context: context,
        trip: widget.trip,
        photosCount: _photosCount,
        totalSpent: _totalSpent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem compartilhada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Premium Necessário'),
          ],
        ),
        content: const Text(
          'Esta funcionalidade está disponível apenas para usuários Premium.\n\n'
          'Faça upgrade agora e desbloqueie:\n'
          '• Viagens ilimitadas\n'
          '• Membros ilimitados\n'
          '• Exportar relatórios PDF\n'
          '• Compartilhar nas redes sociais\n'
          '• Sem anúncios',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumUpgradePage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Fazer Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Compartilhamento'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Premium
            FutureBuilder<bool>(
              future: SubscriptionService.hasAdvancedInsights(),
              builder: (context, snapshot) {
                final hasPremium = snapshot.data ?? false;
                if (hasPremium) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.workspace_premium,
                              color: Colors.amber, size: 40),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Desbloqueie Recursos Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '✓ Viagens ilimitadas\n'
                        '✓ Membros ilimitados\n'
                        '✓ Fotos ilimitadas\n'
                        '✓ Exportar relatórios PDF\n'
                        '✓ Sem anúncios\n'
                        '✓ Suporte prioritário',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PremiumUpgradePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Fazer Upgrade Agora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Resumo da Viagem
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.destination,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.trip.startDate != null &&
                              widget.trip.endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(widget.trip.startDate!)} - '
                              '${DateFormat('dd/MM/yyyy').format(widget.trip.endDate!)}'
                          : 'Datas não definidas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.receipt_long,
                          label: 'Despesas',
                          value: '${widget.expenses.length}',
                        ),
                        _buildStatItem(
                          icon: Icons.attach_money,
                          label: 'Total Gasto',
                          value: _currencyFormat.format(_totalSpent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Relatório por Moeda
            _buildCurrencyBreakdown(),

            const SizedBox(height: 24),

            // Botão Exportar PDF
            _buildActionButton(
              icon: Icons.picture_as_pdf,
              label: 'Exportar Relatório PDF',
              description: 'Gere um relatório completo da sua viagem em PDF',
              color: Colors.red,
              isLoading: _isExporting,
              onPressed: _exportPDF,
            ),

            const SizedBox(height: 24),

            // Informações sobre os relatórios
            Card(
              elevation: 1,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Sobre os Relatórios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O relatório PDF inclui:\n'
                      '• Resumo completo da viagem\n'
                      '• Análise financeira detalhada\n'
                      '• Tabela de todas as despesas\n'
                      '• Gráficos de gastos por categoria\n\n'
                      'A imagem para redes sociais:\n'
                      '• Formato otimizado para Instagram Stories\n'
                      '• Design profissional e atraente\n'
                      '• Estatísticas da sua viagem',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBreakdown() {
    // Agrupar despesas por moeda
    final Map<String, List<Expense>> expensesByCurrency = {};
    for (final expense in widget.expenses) {
      if (!expensesByCurrency.containsKey(expense.currency)) {
        expensesByCurrency[expense.currency] = [];
      }
      expensesByCurrency[expense.currency]!.add(expense);
    }

    // Se todas as despesas são em BRL, não mostrar o card
    if (expensesByCurrency.length == 1 &&
        expensesByCurrency.containsKey('BRL')) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange,
                    color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Gastos por Moeda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...expensesByCurrency.entries.map((entry) {
              final currency = entry.key;
              final expenses = entry.value;
              final totalInOriginal = expenses.fold<double>(
                0.0,
                (sum, exp) => sum + exp.originalValue,
              );
              final totalConverted = expenses.fold<double>(
                0.0,
                (sum, exp) => sum + exp.value,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currency,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${expenses.length} ${expenses.length == 1 ? 'despesa' : 'despesas'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total original:',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ExchangeRateService.formatCurrency(
                            totalInOriginal,
                            currency,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (currency != 'BRL') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Convertido (BRL):',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(totalConverted),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Taxa média:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '1 $currency ≈ ${(totalConverted / totalInOriginal).toStringAsFixed(4)} BRL',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Geral (BRL):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(_totalSpent),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
