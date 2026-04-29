import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';
import '../services/subscription_service.dart';
import 'premium_upgrade_page.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final TripController controller = TripController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController destinationController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String _selectedObjective = 'Descanso';
  String _baseCurrency = 'BRL';
  bool _isNomad = false;
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _objectives = [
    'Descanso',
    'Aventura',
    'Trabalho',
    'Cultural',
    'Gastronômico',
  ];
  final List<String> _currencies = ['BRL', 'USD', 'EUR', 'GBP', 'ARS'];

  final List<String> _popularDestinations = [
    'Orlando, EUA',
    'Paris, França',
    'Tokyo, Japão',
    'Roma, Itália',
    'Rio de Janeiro, Brasil',
    'Londres, Inglaterra',
    'Nova York, EUA',
    'Cancún, México',
  ];

  int get _tripDuration {
    if (_startDate == null || _endDate == null || _isNomad) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _showConfirmationDialog() async {
    if (!formKey.currentState!.validate()) return;

    if (!_isNomad && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Defina as datas da viagem."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    //verificao do premium
    final canCreate = await SubscriptionService.canCreateTrip();
    if (!canCreate) {
      if (!mounted) return;
      _showPremiumRequiredDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Semantics(
        focused: true,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_outlined, color: Colors.green),
              SizedBox(width: 10),
              Text("Confirmar Viagem"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Deseja criar a viagem com estes detalhes?",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow(
                Icons.location_on,
                "Destino",
                destinationController.text,
              ),
              _buildSummaryRow(
                Icons.calendar_month,
                "Período",
                _isNomad
                    ? "Nômade"
                    : "${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}",
              ),
              _buildSummaryRow(
                Icons.payments,
                "Orçamento",
                "$_baseCurrency ${budgetController.text}",
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Editar", style: TextStyle(color: Colors.grey)),
            ),
            Semantics(
              button: true,
              label: "Confirmar todos os dados e criar viagem no sistema",
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _createTrip();
                },
                child: const Text("Confirmar e Criar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _createTrip() async {
    final uid = _auth.currentUser?.uid ?? '';
    setState(() => _isLoading = true);
    try {
      final newTrip = Trip(
        id: '',
        ownerId: uid,
        destination: destinationController.text.trim(),
        budget: double.tryParse(budgetController.text) ?? 0.0,
        baseCurrency: _baseCurrency,
        objective: _selectedObjective,
        isNomad: _isNomad,
        members: [uid],
        createdAt: DateTime.now(),
        startDate: _startDate,
        endDate: _isNomad ? null : _endDate,
      );
      await controller.addTrip(newTrip);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text("Planejar Viagem")),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: "Campo: Para onde você vai?",
                      child: const Text(
                        "Destino",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        hintText: "Digite a cidade",
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Informe o destino" : null,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Sugestões populares:",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularDestinations.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Semantics(
                            button: true,
                            label: "Sugestão: ${_popularDestinations[index]}",
                            child: ActionChip(
                              label: Text(_popularDestinations[index]),
                              onPressed: () => setState(
                                () => destinationController.text =
                                    _popularDestinations[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Campo de Orçamento
                    const Text(
                      "Orçamento",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            value: _baseCurrency,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: _currencies
                                .map(
                                  (currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _baseCurrency = value!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: "Ex: 5000",
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Informe o orçamento" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Campo de Objetivo
                    const Text(
                      "Objetivo da Viagem",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedObjective,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _objectives
                          .map(
                            (obj) =>
                                DropdownMenuItem(value: obj, child: Text(obj)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedObjective = value!),
                    ),
                    const SizedBox(height: 30),

                    Semantics(
                      label: "Seletor de datas da viagem",
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildDateTile(
                                  "Ida",
                                  _startDate,
                                  () => _pickDate(true),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                _buildDateTile(
                                  "Volta",
                                  _endDate,
                                  () => _pickDate(false),
                                  enabled: !_isNomad,
                                ),
                              ],
                            ),
                            SwitchListTile(
                              title: const Text("Modo Nômade"),
                              subtitle: const Text("Sem data de volta"),
                              value: _isNomad,
                              onChanged: (v) => setState(() => _isNomad = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Semantics(
                        button: true,
                        label: "Botão para revisar e criar viagem",
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _showConfirmationDialog,
                          child: const Text(
                            "CRIAR VIAGEM",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateTile(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        label:
            "Selecionar data de $label. Atual: ${date != null ? DateFormat('dd/MM').format(date) : 'Não definida'}",
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.3,
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  date == null
                      ? "Selecionar"
                      : DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null)
      setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 10),
            const Text("Premium Necessário"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Você atingiu o limite de viagens do plano gratuito.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "Com Premium você tem:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem("Viagens ilimitadas"),
                  _buildBenefitItem("Membros ilimitados por viagem"),
                  _buildBenefitItem("Insights avançados com IA"),
                  _buildBenefitItem("Suporte prioritário"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Agora não"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumUpgradePage(),
                ),
              );
            },
            child: const Text("Fazer Upgrade"),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: Text(
        "• $text",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
