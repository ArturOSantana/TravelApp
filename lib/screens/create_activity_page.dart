import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import '../services/notification_service.dart';

class CreateActivityPage extends StatefulWidget {
  final String tripId;
  const CreateActivityPage({super.key, required this.tripId});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final TripController _controller = TripController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final estimatedCostController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'general';
  String _selectedPeriod = 'flexivel';
  int _priority = 0;
  int _durationMinutes = 90;
  bool _isOutdoor = false;

  static const List<Map<String, String>> _categoryOptions = [
    {'value': 'general', 'label': 'Geral'},
    {'value': 'gastronomia', 'label': 'Gastronomia'},
    {'value': 'cultura', 'label': 'Cultura'},
    {'value': 'natureza', 'label': 'Natureza'},
    {'value': 'compras', 'label': 'Compras'},
    {'value': 'aventura', 'label': 'Aventura'},
    {'value': 'vida_noturna', 'label': 'Vida noturna'},
  ];

  static const List<Map<String, String>> _periodOptions = [
    {'value': 'flexivel', 'label': 'Flexível'},
    {'value': 'morning', 'label': 'Manhã'},
    {'value': 'afternoon', 'label': 'Tarde'},
    {'value': 'night', 'label': 'Noite'},
  ];

  void _saveActivity() async {
    if (titleController.text.trim().isEmpty) return;

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final estimatedCost =
        double.tryParse(
          estimatedCostController.text.replaceAll(',', '.').trim(),
        ) ??
        0;

    final activity = Activity(
      id: '',
      tripId: widget.tripId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      time: combinedDateTime,
      location: locationController.text.trim(),
      category: _selectedCategory,
      estimatedCost: estimatedCost,
      durationMinutes: _durationMinutes,
      period: _selectedPeriod,
      isOutdoor: _isOutdoor,
      priority: _priority,
      tags: [_selectedCategory],
      source: 'manual',
    );

    try {
      await _controller.addActivity(activity);

      await NotificationService.scheduleNotification(
        id: combinedDateTime.millisecondsSinceEpoch.remainder(100000),
        title: "Lembrete: ${activity.title}",
        body: "Sua atividade em ${activity.location} começa agora!",
        scheduledDate: combinedDateTime,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Atividade"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "O que você vai fazer?",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descrição",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Localização / Endereço",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categoryOptions
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value ?? 'general');
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Período ideal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: _periodOptions
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPeriod = value ?? 'flexivel');
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estimatedCostController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Custo estimado",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text("Data e Horário"),
                subtitle: Text(
                  "${_selectedDate.day}/${_selectedDate.month} às ${_selectedTime.format(context)}",
                ),
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.deepPurple,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    if (context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = time;
                        });
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timelapse_outlined),
                  const SizedBox(width: 8),
                  const Text('Duração estimada'),
                  const Spacer(),
                  IconButton(
                    onPressed: _durationMinutes > 30
                        ? () => setState(() => _durationMinutes -= 30)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_durationMinutes min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _durationMinutes += 30),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high_outlined),
                  const SizedBox(width: 8),
                  const Text('Prioridade'),
                  const Spacer(),
                  IconButton(
                    onPressed: _priority > 0
                        ? () => setState(() => _priority--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_priority',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _priority < 3
                        ? () => setState(() => _priority++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isOutdoor,
              contentPadding: EdgeInsets.zero,
              title: const Text('Atividade ao ar livre'),
              subtitle: const Text(
                'Ajuda o roteiro inteligente a considerar clima e contexto.',
              ),
              onChanged: (value) {
                setState(() => _isOutdoor = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveActivity,
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "SALVAR NO ROTEIRO",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Made with Bob
