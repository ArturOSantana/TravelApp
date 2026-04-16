import 'package:flutter/material.dart';

import '../controllers/packing_checklist_controller.dart';
import '../models/packing_checklist.dart';

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

  List<String> get _categories => PackingChecklistController.categories;

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
            icon: const Icon(Icons.playlist_add_check_circle_outlined),
            tooltip: 'Usar template',
            onPressed: _showTemplateDialog,
          ),
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
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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
                      'Checklist da bagagem',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(viewData.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
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
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatCard(
                icon: Icons.pending_actions_outlined,
                label: 'Pendentes',
                value: '${viewData.pendingCount}',
              ),
              _buildStatCard(
                icon: Icons.priority_high_outlined,
                label: 'Prioridade',
                value:
                    '${viewData.pendingPriorityCount}/${viewData.priorityCount}',
              ),
              _buildStatCard(
                icon: Icons.category_outlined,
                label: 'Categorias',
                value: '${viewData.categoriesCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              fillColor: Colors.grey[100],
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
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: Colors.deepPurple,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Icons.pending_outlined, size: 16),
                label: const Text('Pendentes', style: TextStyle(fontSize: 12)),
                selected: _showOnlyPending,
                onSelected: (_) {
                  setState(() => _showOnlyPending = !_showOnlyPending);
                },
              ),
              FilterChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Icons.priority_high_outlined, size: 16),
                label: const Text(
                  'Prioritários',
                  style: TextStyle(fontSize: 12),
                ),
                selected: _showOnlyPriority,
                onSelected: (_) {
                  setState(() => _showOnlyPriority = !_showOnlyPriority);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(PackingChecklistViewData viewData) {
    if (viewData.allItems.isEmpty) {
      return _buildEmptyState();
    }

    if (viewData.filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 68,
                color: Colors.grey[350],
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum item encontrado com os filtros atuais.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajuste a busca, categoria ou prioridades para visualizar outros itens.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        ...viewData.groupedItems.entries.map(
          (entry) => _buildCategorySection(entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<PackingItem> items) {
    final checked = items.where((item) => item.isChecked).length;
    final progress = items.isEmpty ? 0.0 : checked / items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.deepPurple.withValues(alpha: 0.10),
              child: Icon(
                _categoryIcon(category),
                color: Colors.deepPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$checked/${items.length}',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurple,
              ),
            ),
          ),
        ),
        children: items.map((item) => _buildItemCard(item)).toList(),
      ),
    );
  }

  Widget _buildItemCard(PackingItem item) {
    final isPriority = _controller.isPriority(item);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: item.isChecked
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isChecked
              ? Colors.green.withValues(alpha: 0.22)
              : isPriority
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _toggleItem(item.id, !item.isChecked),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isChecked ? Colors.green : Colors.white,
                  border: Border.all(
                    color: item.isChecked ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isChecked ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (isPriority)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high_outlined,
                                size: 12,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Prioridade',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcon(item.category),
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.category,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      if (item.quantity > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Qtd. ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if ((item.notes ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.notes!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: item.isPriority
                      ? 'Remover prioridade'
                      : 'Tornar prioritário',
                  onPressed: () => _togglePriority(item.id, !item.isPriority),
                  icon: Icon(
                    item.isPriority
                        ? Icons.priority_high
                        : Icons.priority_high_outlined,
                    color: item.isPriority ? Colors.orange : Colors.grey[600],
                    size: 20,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditItemDialog(item);
                    } else if (value == 'togglePriority') {
                      _togglePriority(item.id, !item.isPriority);
                    } else if (value == 'delete') {
                      _deleteItem(item.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'togglePriority',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.isPriority
                              ? Icons.priority_high_outlined
                              : Icons.priority_high,
                          color: Colors.orange,
                        ),
                        title: Text(
                          item.isPriority
                              ? 'Remover prioridade'
                              : 'Tornar prioritário',
                        ),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Remover'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[350]),
            const SizedBox(height: 18),
            const Text(
              'Seu checklist ainda está vazio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione itens manualmente ou aplique um template para começar a organizar a viagem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showTemplateDialog,
                  icon: const Icon(Icons.library_add_check_outlined),
                  label: const Text('Usar template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(PackingItem item) {
    _showItemDialog(existingItem: item);
  }

  void _showItemDialog({PackingItem? existingItem}) {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final notesController = TextEditingController(
      text: existingItem?.notes ?? '',
    );
    String selectedCategory = existingItem?.category ?? 'Roupas';
    int quantity = existingItem?.quantity ?? 1;
    bool isPriority = existingItem?.isPriority ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Text(existingItem == null ? 'Novo item' : 'Editar item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .where((cat) => cat != 'Todos')
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(_categoryIcon(cat), size: 18),
                              const SizedBox(width: 8),
                              Text(cat),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.numbers_outlined),
                      const SizedBox(width: 8),
                      const Text('Quantidade'),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setModalState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setModalState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: isPriority,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marcar como prioritário'),
                  subtitle: const Text(
                    'Itens prioritários aparecem destacados no checklist.',
                  ),
                  secondary: Icon(
                    isPriority
                        ? Icons.priority_high
                        : Icons.priority_high_outlined,
                    color: isPriority ? Colors.orange : Colors.grey,
                  ),
                  onChanged: (value) {
                    setModalState(() => isPriority = value);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText:
                        'Ex.: levar na mala de mão, item sensível, uso diário',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final notes = notesController.text.trim();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);

                if (name.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Informe o nome do item.')),
                  );
                  return;
                }

                try {
                  if (existingItem == null) {
                    await _controller.addItem(
                      tripId: widget.tripId,
                      name: name,
                      category: selectedCategory,
                      quantity: quantity,
                      notes: notes.isEmpty ? null : notes,
                      isPriority: isPriority,
                    );
                  } else {
                    await _controller.updateItem(
                      itemId: existingItem.id,
                      name: name,
                      category: selectedCategory,
                      quantity: quantity,
                      notes: notes.isEmpty ? null : notes,
                      isPriority: isPriority,
                    );
                  }

                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        existingItem == null
                            ? 'Item adicionado com sucesso.'
                            : 'Item atualizado com sucesso.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(
                existingItem == null ? Icons.add : Icons.save_outlined,
              ),
              label: Text(existingItem == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    final templates = [
      {
        'title': 'Praia',
        'icon': Icons.beach_access_outlined,
        'items': PackingTemplate.getBeachTemplate(),
      },
      {
        'title': 'Montanha',
        'icon': Icons.terrain_outlined,
        'items': PackingTemplate.getMountainTemplate(),
      },
      {
        'title': 'Cidade',
        'icon': Icons.location_city_outlined,
        'items': PackingTemplate.getCityTemplate(),
      },
      {
        'title': 'Essenciais',
        'icon': Icons.checklist_rtl_outlined,
        'items': PackingTemplate.getEssentialsTemplate(),
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aplicar template'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: templates.map((template) {
              return ListTile(
                leading: Icon(
                  template['icon'] as IconData,
                  color: Colors.deepPurple,
                ),
                title: Text(template['title'] as String),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final addedCount = await _controller.addTemplateItems(
                      tripId: widget.tripId,
                      items: List<Map<String, String>>.from(
                        template['items'] as List,
                      ),
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          addedCount == 0
                              ? 'Nenhum item novo foi adicionado.'
                              : '$addedCount itens adicionados ao checklist.',
                        ),
                        backgroundColor: addedCount == 0 ? null : Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao aplicar template: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
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
      case 'Medicamentos':
        return Icons.medication_outlined;
      case 'Calçados':
        return Icons.hiking_outlined;
      case 'Acessórios':
        return Icons.watch_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Future<void> _toggleItem(String itemId, bool isChecked) async {
    try {
      await _controller.toggleItem(itemId: itemId, isChecked: isChecked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsChecked() async {
    try {
      await _controller.markAllAsChecked(widget.tripId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os itens foram marcados como prontos.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar itens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePriority(String itemId, bool isPriority) async {
    try {
      await _controller.togglePriority(itemId: itemId, isPriority: isPriority);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPriority
                ? 'Item marcado como prioritário.'
                : 'Prioridade removida do item.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar prioridade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _controller.deleteItem(itemId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removido com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
