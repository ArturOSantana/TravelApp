import 'package:flutter/material.dart';

import '../controllers/packing_checklist_controller.dart';
import '../models/packing_checklist.dart';
import '../data/packing_templates.dart';
import 'select_packing_template_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist da Viagem'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: 'Usar template',
            onPressed: _openTemplateSelector,
          ),
          IconButton(
            icon: const Icon(Icons.done_all_outlined),
            tooltip: 'Marcar tudo como pronto',
            onPressed: _markAllAsChecked,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Erro ao carregar checklist: ${snapshot.error}'));
            }

            final viewData = snapshot.data ?? PackingChecklistViewData.empty();

            return Column(
              children: [
                _buildHeader(viewData),
                _buildFilterBar(),
                Expanded(child: _buildItemsList(viewData)),
              ],
            );
          },
        ),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
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
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.luggage_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progresso da Bagagem',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viewData.totalCount == 0
                          ? 'Adicione os primeiros itens'
                          : '${viewData.checkedCount}/${viewData.totalCount} prontos',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(viewData.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: viewData.progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar item...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase().trim());
            },
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<String>>(
            stream: _controller.watchTripCategories(widget.tripId),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? ['Todos'];
              return SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(category,
                            style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(PackingChecklistViewData viewData) {
    if (viewData.allItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: viewData.groupedItems.entries
          .map(
            (entry) => _buildCategorySection(entry.key, entry.value),
          )
          .toList(),
    );
  }

  Widget _buildCategorySection(String category, List<PackingItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(category,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        leading: Icon(_categoryIcon(category),
            color: Theme.of(context).colorScheme.primary, size: 20),
        children: items.map((item) => _buildItemCard(item)).toList(),
      ),
    );
  }

  Widget _buildItemCard(PackingItem item) {
    return ListTile(
      leading: Checkbox(
        value: item.isChecked,
        activeColor: Colors.green,
        onChanged: (val) => _toggleItem(item.id, val ?? false),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked
              ? Colors.grey
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        onPressed: () => _deleteItem(item.id),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 18),
          const Text('Seu checklist está vazio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Adicione itens para começar a organizar.'),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<String>>(
        stream: _controller.watchTripCategories(widget.tripId),
        builder: (context, snapshot) {
          final categories =
              (snapshot.data ?? ['Outros']).where((c) => c != 'Todos').toList();

          String selectedCategory =
              categories.contains('Outros') ? 'Outros' : categories.first;

          return StatefulBuilder(
            builder: (context, setModalState) => AlertDialog(
              title: const Text('Novo item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nome do item'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedCategory = val!),
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await _controller.addItem(
                        tripId: widget.tripId,
                        name: nameController.text,
                        category: selectedCategory,
                        quantity: 1,
                      );
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Roupas':
        return Icons.checkroom_outlined;
      case 'Documentos':
        return Icons.description_outlined;
      case 'Eletrônicos':
        return Icons.devices_outlined;
      case 'Higiene':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Future<void> _toggleItem(String itemId, bool isChecked) async =>
      await _controller.toggleItem(itemId: itemId, isChecked: isChecked);
  Future<void> _markAllAsChecked() async =>
      await _controller.markAllAsChecked(widget.tripId);
  Future<void> _deleteItem(String itemId) async =>
      await _controller.deleteItem(itemId);

  Future<void> _openTemplateSelector() async {
    final template = await Navigator.push<PackingTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPackingTemplatePage(tripId: widget.tripId),
      ),
    );

    if (template != null && mounted) {
      _applyTemplate(template);
    }
  }

  Future<void> _applyTemplate(PackingTemplate template) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Adicionando itens do template...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Converter itens do template para o formato esperado
      final items = template.items.map((item) => item.toMap()).toList();

      // Adicionar itens usando o controller
      final addedCount = await _controller.addTemplateItems(
        tripId: widget.tripId,
        items: items,
      );

      if (mounted) {
        Navigator.pop(context); // Fechar loading

        // Mostrar resultado
        final message = addedCount > 0
            ? '$addedCount ${addedCount == 1 ? 'item adicionado' : 'itens adicionados'} com sucesso!'
            : 'Todos os itens do template já existem no checklist.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: addedCount > 0 ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar itens: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
