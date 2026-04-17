import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/packing_checklist_controller.dart';
import '../models/packing_checklist.dart';
import '../models/trip.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';

class PackingChecklistPage extends StatefulWidget {
  final String tripId;
  const PackingChecklistPage({super.key, required this.tripId});

  @override
  State<PackingChecklistPage> createState() => _PackingChecklistPageState();
}

class _PackingChecklistPageState extends State<PackingChecklistPage> {
  final PackingChecklistController _controller = PackingChecklistController();

  String _selectedCategory = 'Todos';
  bool _showOnlyPending = false;
  bool _showOnlyPriority = false;
  String _searchQuery = '';

  WeatherForecast? _weatherForecast;
  bool _loadingWeather = false;
  List<String> _aiSuggestions = [];
  bool _isGeneratingAI = false;

  List<String> get _categories => PackingChecklistController.categories;

  @override
  void initState() {
    super.initState();
    _loadWeatherSuggestions();
  }

  Future<void> _loadWeatherSuggestions() async {
    setState(() => _loadingWeather = true);

    try {
      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (tripDoc.exists) {
        final trip = Trip.fromFirestore(tripDoc);
        final forecast = await WeatherService.getForecast(trip.destination);

        if (mounted) {
          setState(() {
            _weatherForecast = forecast;
            _loadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  Future<void> _generateAISuggestions() async {
    setState(() => _isGeneratingAI = true);
    try {
      final tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
      if (tripDoc.exists) {
        final trip = Trip.fromFirestore(tripDoc);
        final weatherText = _weatherForecast != null 
          ? "${_weatherForecast!.currentTemp}°C, ${_weatherForecast!.currentDesc}" 
          : "Clima variado";
        
        final suggestions = await AIService.getChecklistSuggestions(trip.destination, weatherText);
        if (mounted) {
          setState(() {
            _aiSuggestions = suggestions;
            _isGeneratingAI = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Checklist de Viagem'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_outlined),
            tooltip: 'Marcar tudo como pronto',
            onPressed: _markAllAsChecked,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<PackingChecklistViewData>(
          stream: _controller.watchViewData(
            tripId: widget.tripId,
            selectedCategory: _selectedCategory,
            showOnlyPending: _showOnlyPending,
            showOnlyPriority: _showOnlyPriority,
            searchQuery: _searchQuery,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final viewData = snapshot.data ?? PackingChecklistViewData.empty();

            return Column(
              children: [
                _buildHeader(viewData),
                _buildAISuggestionsCard(),
                _buildFilterBar(),
                Expanded(child: _buildItemsList(viewData)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAISuggestionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text("Sugestões da IA", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_weatherForecast != null)
                Text("${_weatherForecast!.currentTemp}°C ${_weatherForecast!.currentDesc}", 
                  style: TextStyle(fontSize: 10, color: Colors.deepPurple[300])),
            ],
          ),
          const SizedBox(height: 10),
          if (_aiSuggestions.isEmpty)
            TextButton(
              onPressed: _isGeneratingAI ? null : _generateAISuggestions,
              child: _isGeneratingAI 
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Que tal pedir ajuda à IA para arrumar a mala?"),
            )
          else
            Wrap(
              spacing: 8,
              children: _aiSuggestions.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                onPressed: () => _controller.addItem(tripId: widget.tripId, name: s, category: 'Outros', quantity: 1),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(PackingChecklistViewData viewData) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.luggage_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checklist da bagagem', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${viewData.checkedCount}/${viewData.totalCount} prontos', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Text('${(viewData.progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: viewData.progress, minHeight: 7, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar item...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(PackingChecklistViewData viewData) {
    if (viewData.allItems.isEmpty) return _buildEmptyState();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: viewData.groupedItems.entries.map((e) => _buildCategorySection(e.key, e.value)).toList(),
    );
  }

  Widget _buildCategorySection(String category, List<PackingItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: items.map((item) => ListTile(
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (v) => _toggleItem(item.id, v!),
          ),
          title: Text(item.name, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteItem(item.id)),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 18),
          const Text('Seu checklist está vazio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _showAddItemDialog, child: const Text("Adicionar Item")),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showItemDialog({PackingItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    String selectedCategory = existingItem?.category ?? 'Roupas';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingItem == null ? 'Novo item' : 'Editar item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do item')),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: _categories.where((c) => c != 'Todos').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => selectedCategory = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              if (existingItem == null) {
                await _controller.addItem(tripId: widget.tripId, name: nameController.text, category: selectedCategory, quantity: 1);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItem(String itemId, bool isChecked) async {
    await _controller.toggleItem(itemId: itemId, isChecked: isChecked);
  }

  Future<void> _markAllAsChecked() async {
    await _controller.markAllAsChecked(widget.tripId);
  }

  Future<void> _togglePriority(String itemId, bool isPriority) async {
    await _controller.togglePriority(itemId: itemId, isPriority: isPriority);
  }

  Future<void> _deleteItem(String itemId) async {
    await _controller.deleteItem(itemId);
  }
}
