import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_packing_template.dart';

class CreateCustomTemplatePage extends StatefulWidget {
  final CustomPackingTemplate? template;

  const CreateCustomTemplatePage({
    super.key,
    this.template,
  });

  @override
  State<CreateCustomTemplatePage> createState() =>
      _CreateCustomTemplatePageState();
}

class _CreateCustomTemplatePageState extends State<CreateCustomTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemNameController = TextEditingController();

  String _selectedIcon = 'inventory_2';
  String _selectedCategory = 'Roupas';
  List<CustomTemplateItem> _items = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Roupas',
    'Calçados',
    'Acessórios',
    'Higiene',
    'Eletrônicos',
    'Documentos',
    'Medicamentos',
    'Outros',
  ];

  final Map<String, IconData> _availableIcons = {
    'inventory_2': Icons.inventory_2,
    'backpack': Icons.backpack,
    'luggage': Icons.luggage,
    'beach_access': Icons.beach_access,
    'terrain': Icons.terrain,
    'location_city': Icons.location_city,
    'business_center': Icons.business_center,
    'nature_people': Icons.nature_people,
    'flight': Icons.flight,
    'hiking': Icons.hiking,
    'sports': Icons.sports,
    'camera': Icons.camera_alt,
    'restaurant': Icons.restaurant,
  };

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description;
      _selectedIcon = widget.template!.iconName;
      _items = List.from(widget.template!.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Template' : 'Criar Template'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações Básicas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Template',
                              hintText: 'Ex: Minha Viagem de Praia',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite um nome para o template';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              hintText: 'Descreva o tipo de viagem',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite uma descrição';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Escolha um Ícone',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableIcons.entries.map((entry) {
                              final isSelected = _selectedIcon == entry.key;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedIcon = entry.key);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    entry.value,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Itens do Template',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_items.length} itens',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _itemNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome do item',
                                    hintText: 'Ex: Protetor solar',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoria',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(
                                        category,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCategory = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add_circle),
                                color: theme.colorScheme.primary,
                                tooltip: 'Adicionar item',
                              ),
                            ],
                          ),
                          if (_items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            ..._buildItemsList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveTemplate,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isEditing ? 'Salvar Alterações' : 'Criar Template',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildItemsList() {
    final groupedItems = <String, List<CustomTemplateItem>>{};
    for (final item in _items) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return groupedItems.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...entry.value.map((item) {
            final index = _items.indexOf(item);
            return ListTile(
              dense: true,
              leading: const Icon(Icons.drag_indicator, size: 20),
              title: Text(item.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  setState(() => _items.removeAt(index));
                },
                color: Colors.red,
              ),
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ],
      );
    }).toList();
  }

  void _addItem() {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do item')),
      );
      return;
    }

    setState(() {
      _items.add(CustomTemplateItem(
        name: _itemNameController.text.trim(),
        category: _selectedCategory,
      ));
      _itemNameController.clear();
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item ao template'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final db = FirebaseFirestore.instance;

      final template = CustomPackingTemplate(
        id: widget.template?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        items: _items,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
      );

      if (widget.template != null) {
        await db
            .collection('custom_packing_templates')
            .doc(widget.template!.id)
            .update(template.toMap());
      } else {
        await db.collection('custom_packing_templates').add(template.toMap());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template != null
                  ? 'Template atualizado com sucesso!'
                  : 'Template criado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar template: $e'),
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

