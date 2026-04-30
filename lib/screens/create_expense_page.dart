import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/exchangerate_service.dart';

class CreateExpensePage extends StatefulWidget {
  final String tripId;
  const CreateExpensePage({super.key, required this.tripId});

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  final _controller = TripController();
  final _auth = FirebaseAuth.instance;

  final titleController = TextEditingController();
  final valueController = TextEditingController();

  final List<String> _categories = [
    'Alimentação',
    'Transporte',
    'Hospedagem',
    'Entretenimento',
    'Compras',
    'Saúde',
    'Outros',
  ];

  String _selectedCategory = 'Alimentação';
  String _selectedCurrency = 'BRL';
  SplitType _selectedSplitType = SplitType.equal;

  Trip? _trip;
  List<UserModel> _members = [];
  String? _payerId;
  final Map<String, double> _customSplits = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final List<String> _currencies = ['BRL', 'USD', 'EUR', 'GBP', 'ARS'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!tripDoc.exists) {
        throw Exception('Viagem não encontrada.');
      }

      _trip = Trip.fromFirestore(tripDoc);
      _selectedCurrency = _trip!.baseCurrency;

      final currentUser = _auth.currentUser;
      final currentUid = currentUser?.uid ?? '';

      final validTripMembers = <String>{
        if (_trip!.ownerId.trim().isNotEmpty) _trip!.ownerId.trim(),
        ..._trip!.members
            .where((id) => id.trim().isNotEmpty)
            .map((id) => id.trim()),
      };

      final bool isRealGroup = _trip!.isGroup || validTripMembers.length > 1;

      if (!isRealGroup && currentUid.isNotEmpty) {
        _members = [
          UserModel(
            uid: currentUid,
            name: (currentUser?.displayName?.trim().isNotEmpty ?? false)
                ? currentUser!.displayName!.trim()
                : 'Você',
            email: currentUser?.email ?? '',
          ),
        ];
      } else {
        final memberIds = <String>{...validTripMembers};
        if (currentUid.isNotEmpty) {
          memberIds.add(currentUid);
        }

        _members = memberIds
            .map(
              (id) => UserModel(
                uid: id,
                name: id == currentUid
                    ? ((currentUser?.displayName?.trim().isNotEmpty ?? false)
                        ? currentUser!.displayName!.trim()
                        : 'Você')
                    : 'Participante',
                email: id == currentUid ? (currentUser?.email ?? '') : '',
              ),
            )
            .toList();

        try {
          final loadedMembers = await _controller
              .getTripMembers(memberIds.toList())
              .timeout(const Duration(seconds: 6));

          if (loadedMembers.isNotEmpty) {
            final Map<String, UserModel> byId = {
              for (final member in _members) member.uid: member,
            };
            for (final member in loadedMembers) {
              final normalizedName = _normalizeMemberName(
                uid: member.uid,
                originalName: member.name,
                email: member.email,
              );

              byId[member.uid] = UserModel(
                uid: member.uid,
                name: normalizedName,
                email: member.email,
                phone: member.phone,
                emergencyContact: member.emergencyContact,
                emergencyPhone: member.emergencyPhone,
                bio: member.bio,
                photoUrl: member.photoUrl,
                isPremium: member.isPremium,
              );
            }
            _members = byId.values.toList();
          }

          _members = _members
              .map(
                (member) => UserModel(
                  uid: member.uid,
                  name: _normalizeMemberName(
                    uid: member.uid,
                    originalName: member.name,
                    email: member.email,
                  ),
                  email: member.email,
                  phone: member.phone,
                  emergencyContact: member.emergencyContact,
                  emergencyPhone: member.emergencyPhone,
                  bio: member.bio,
                  photoUrl: member.photoUrl,
                  isPremium: member.isPremium,
                ),
              )
              .toList();
        } catch (_) {
          // Mantém fallback local para a tela abrir mesmo sem buscar perfis completos.
        }

        if (_members.isEmpty && currentUid.isNotEmpty) {
          _members = [
            UserModel(
              uid: currentUid,
              name: (currentUser?.displayName?.trim().isNotEmpty ?? false)
                  ? currentUser!.displayName!.trim()
                  : 'Você',
              email: currentUser?.email ?? '',
            ),
          ];
        }
      }

      _payerId = currentUid.isNotEmpty
          ? currentUid
          : (_members.isNotEmpty ? _members.first.uid : null);

      for (final m in _members) {
        _customSplits[m.uid] = 0.0;
      }
    } catch (e) {
      _loadError = 'Não foi possível carregar os dados da viagem.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveExpense() async {
    if (titleController.text.trim().isEmpty ||
        valueController.text.trim().isEmpty ||
        _trip == null ||
        _payerId == null ||
        _members.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double originalVal =
          double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0.0;
      if (originalVal <= 0) {
        _showError('Informe um valor válido para o gasto.');
        return;
      }

      double finalVal = originalVal;
      double exchangeRate = 1.0;
      DateTime? conversionDate;

      if (_selectedCurrency != _trip!.baseCurrency) {
        double? rate = await ExchangeRateService.getExchangeRate(
          from: _selectedCurrency,
          to: _trip!.baseCurrency,
        );
        exchangeRate = rate ?? 1.0;
        finalVal = originalVal * exchangeRate;
        conversionDate = DateTime.now();
      }

      final Map<String, double> finalSplits = _buildFinalSplits(finalVal);
      if (finalSplits.isEmpty) return;

      final expense = Expense(
        id: '',
        tripId: widget.tripId,
        title: titleController.text.trim(),
        value: finalVal,
        originalValue: originalVal,
        currency: _selectedCurrency,
        category: _selectedCategory,
        payerId: _payerId!,
        date: DateTime.now(),
        splitType: _selectedSplitType,
        splits: finalSplits,
        exchangeRateUsed: exchangeRate,
        conversionDate: conversionDate,
      );

      await _controller.addExpense(expense);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, double> _buildFinalSplits(double total) {
    final Map<String, double> finalSplits = {};

    if (_selectedSplitType == SplitType.equal) {
      final perPerson = total / _members.length;
      for (final member in _members) {
        finalSplits[member.uid] = perPerson;
      }
      return finalSplits;
    }

    if (_selectedSplitType == SplitType.exact) {
      double sum = 0;
      for (final member in _members) {
        final value = _customSplits[member.uid] ?? 0.0;
        finalSplits[member.uid] = value;
        sum += value;
      }

      if ((sum - total).abs() > 0.01) {
        _showError(
          'Na divisão por valor exato, a soma deve ser igual ao total do gasto.',
        );
        return {};
      }
      return finalSplits;
    }

    if (_selectedSplitType == SplitType.percentage) {
      double percentageSum = 0;
      for (final member in _members) {
        final percentage = _customSplits[member.uid] ?? 0.0;
        percentageSum += percentage;
        finalSplits[member.uid] = total * (percentage / 100);
      }

      if ((percentageSum - 100).abs() > 0.01) {
        _showError('Na divisão por porcentagem, a soma deve ser 100%.');
        return {};
      }
      return finalSplits;
    }

    double totalShares = 0;
    for (final member in _members) {
      totalShares += _customSplits[member.uid] ?? 0.0;
    }

    if (totalShares <= 0) {
      _showError('Informe ao menos uma quantidade de cotas maior que zero.');
      return {};
    }

    for (final member in _members) {
      final shares = _customSplits[member.uid] ?? 0.0;
      finalSplits[member.uid] = total * (shares / totalShares);
    }

    return finalSplits;
  }

  String _normalizeMemberName({
    required String uid,
    required String originalName,
    required String email,
  }) {
    final currentUid = _auth.currentUser?.uid ?? '';
    if (uid == currentUid) return 'Eu';

    final cleanedName = originalName.trim();
    if (cleanedName.isNotEmpty &&
        cleanedName.toLowerCase() != 'participante' &&
        cleanedName.toLowerCase() != 'você') {
      return cleanedName;
    }

    final cleanedEmail = email.trim();
    if (cleanedEmail.isNotEmpty && cleanedEmail.contains('@')) {
      return cleanedEmail.split('@').first;
    }

    return 'Outro participante';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Novo Gasto"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadError = null;
                    });
                    _loadData();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Novo Gasto"),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhum participante encontrado para esta viagem.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Gasto"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickInfo(),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Descrição",
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "Categoria",
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: "Moeda",
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCurrency = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quanto?",
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_members.length > 1) ...[
              const SizedBox(height: 25),
              const Text(
                "Quem pagou?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildPayerSelector(),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Como dividir?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<SplitType>(
                    value: _selectedSplitType,
                    items: SplitType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_splitTypeLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSplitType = v!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _splitTypeDescription(_selectedSplitType),
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildSplitEditor(),
            ] else ...[
              const SizedBox(height: 25),
              Card(
                color: Colors.green[50],
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Viagem solo: este gasto será lançado somente para você, sem divisão de grupo.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveExpense,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text("REGISTRAR GASTO"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Moeda da viagem: ${_trip?.baseCurrency}. Conversão automática ativa.",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayerSelector() {
    if (_members.length == 1) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.green[100],
            child: const Icon(Icons.person, color: Colors.green),
          ),
          title: const Text('Eu'),
          subtitle: const Text('Você é a única pessoa nesta viagem.'),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final m = _members[index];
          final isSelected = _payerId == m.uid;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(m.uid == _auth.currentUser?.uid ? "Eu" : m.name),
              selected: isSelected,
              onSelected: (v) => setState(() => _payerId = m.uid),
              selectedColor: Colors.green[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitEditor() {
    final total =
        double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0.0;

    if (_selectedSplitType == SplitType.equal) {
      final share = _members.isEmpty ? 0.0 : total / _members.length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(
            "Todos participam igualmente: ${_formatMoney(share)} para cada pessoa.",
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._members.map((m) {
          final hint = _selectedSplitType == SplitType.exact
              ? 'Valor'
              : _selectedSplitType == SplitType.percentage
                  ? '%'
                  : 'Cotas';

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(m.uid == _auth.currentUser?.uid ? 'Eu' : m.name),
            subtitle: Text(_fieldHelpText()),
            trailing: SizedBox(
              width: 110,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _customSplits[m.uid] =
                    double.tryParse(v.replaceAll(',', '.')) ?? 0.0,
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _buildSplitSummary(total),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  String _splitTypeLabel(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Igualmente';
      case SplitType.exact:
        return 'Valor exato';
      case SplitType.percentage:
        return 'Porcentagem';
      case SplitType.shares:
        return 'Por cotas';
    }
  }

  String _splitTypeDescription(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'O valor será dividido em partes iguais entre todos os membros.';
      case SplitType.exact:
        return 'Você informa quanto cada pessoa deve pagar.';
      case SplitType.percentage:
        return 'Você informa o percentual de cada pessoa. A soma deve dar 100%.';
      case SplitType.shares:
        return 'Você informa cotas proporcionais. Ex.: 2, 1 e 1.';
    }
  }

  String _fieldHelpText() {
    switch (_selectedSplitType) {
      case SplitType.exact:
        return 'Informe o valor desta pessoa.';
      case SplitType.percentage:
        return 'Informe a porcentagem desta pessoa.';
      case SplitType.shares:
        return 'Informe a quantidade de cotas desta pessoa.';
      case SplitType.equal:
        return 'Divisão automática.';
    }
  }

  String _buildSplitSummary(double total) {
    if (_selectedSplitType == SplitType.exact) {
      final sum = _members.fold<double>(
        0.0,
        (acc, member) => acc + (_customSplits[member.uid] ?? 0.0),
      );
      return 'Total informado: ${_formatMoney(sum)} de ${_formatMoney(total)}';
    }

    if (_selectedSplitType == SplitType.percentage) {
      final sum = _members.fold<double>(
        0.0,
        (acc, member) => acc + (_customSplits[member.uid] ?? 0.0),
      );
      return 'Percentual informado: ${sum.toStringAsFixed(1)}% de 100%';
    }

    final shares = _members.fold<double>(
      0.0,
      (acc, member) => acc + (_customSplits[member.uid] ?? 0.0),
    );
    return 'Total de cotas informado: ${shares.toStringAsFixed(1)}';
  }

  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2)}';
}
