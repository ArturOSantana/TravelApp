import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/packing_checklist.dart';

class PackingChecklistPage extends StatefulWidget {
  final String tripId;
  const PackingChecklistPage({super.key, required this.tripId});

  @override
  State<PackingChecklistPage> createState() => _PackingChecklistPageState();
}

class _PackingChecklistPageState extends State<PackingChecklistPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _selectedCategory = 'Todos';
  final List<String> _categories = [
    'Todos',
    'Roupas',
    'Documentos',
    'Eletrônicos',
    'Higiene',
    'Medicamentos',
    'Calçados',
    'Acessórios',
    'Outros',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist de Bagagem'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Usar Template',
            onPressed: () => _showTemplateDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Item'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildProgressCard(),
          _buildCategoryFilter(),
          Expanded(child: _buildItemsList()),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('packing_items')
          .where('tripId', isEqualTo: widget.tripId)
          .where('userId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final items = snapshot.data!.docs
            .map((doc) => PackingItem.fromFirestore(doc))
            .toList();
        final checkedCount = items.where((item) => item.isChecked).length;
        final totalCount = items.length;
        final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progresso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$checkedCount / $totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                progress == 1.0
                    ? '🎉 Tudo pronto!'
                    : '${(progress * 100).toStringAsFixed(0)}% completo',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Colors.deepPurple,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('packing_items')
          .where('tripId', isEqualTo: widget.tripId)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var items = snapshot.data!.docs
            .map((doc) => PackingItem.fromFirestore(doc))
            .toList();

        // Filtrar por categoria
        if (_selectedCategory != 'Todos') {
          items = items
              .where((item) => item.category == _selectedCategory)
              .toList();
        }

        if (items.isEmpty) {
          return Center(child: Text('Nenhum item em "$_selectedCategory"'));
        }

        // Agrupar por categoria
        final Map<String, List<PackingItem>> groupedItems = {};
        for (var item in items) {
          groupedItems.putIfAbsent(item.category, () => []).add(item);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedItems.length,
          itemBuilder: (context, index) {
            final category = groupedItems.keys.elementAt(index);
            final categoryItems = groupedItems[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCategory == 'Todos') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
                ...categoryItems.map((item) => _buildItemCard(item)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(PackingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (value) => _toggleItem(item.id, value ?? false),
          activeColor: Colors.deepPurple,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: item.notes != null
            ? Text(item.notes!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.quantity > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Nenhum item na bagagem',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Adicione itens ou use um template',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showTemplateDialog,
            icon: const Icon(Icons.add_box),
            label: const Text('Usar Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'Roupas';
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Item',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .where((cat) => cat != 'Todos')
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Quantidade:'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addItem(
                    nameController.text,
                    selectedCategory,
                    quantity,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTemplateOption(
              '🏖️ Praia',
              PackingTemplate.getBeachTemplate(),
            ),
            _buildTemplateOption(
              '⛰️ Montanha',
              PackingTemplate.getMountainTemplate(),
            ),
            _buildTemplateOption(
              '🏙️ Cidade',
              PackingTemplate.getCityTemplate(),
            ),
            _buildTemplateOption(
              '✈️ Essenciais',
              PackingTemplate.getEssentialsTemplate(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String title, List<Map<String, String>> items) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        _addTemplateItems(items);
      },
    );
  }

  Future<void> _addItem(
    String name,
    String category,
    int quantity,
    String? notes,
  ) async {
    await _db.collection('packing_items').add({
      'tripId': widget.tripId,
      'userId': _userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': false,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addTemplateItems(List<Map<String, String>> items) async {
    final batch = _db.batch();

    for (var item in items) {
      final docRef = _db.collection('packing_items').doc();
      batch.set(docRef, {
        'tripId': widget.tripId,
        'userId': _userId,
        'name': item['name'],
        'category': item['category'],
        'quantity': 1,
        'isChecked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${items.length} itens adicionados!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleItem(String itemId, bool isChecked) async {
    await _db.collection('packing_items').doc(itemId).update({
      'isChecked': isChecked,
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _db.collection('packing_items').doc(itemId).delete();
  }
}

