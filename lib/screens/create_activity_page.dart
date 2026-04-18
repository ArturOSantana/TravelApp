import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import '../services/notification_service.dart';

class CreateActivityPage extends StatefulWidget {
  final String tripId;
  final Activity? activity;

  const CreateActivityPage({super.key, required this.tripId, this.activity});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final TripController _controller = TripController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final categoryController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      titleController.text = widget.activity!.title;
      locationController.text = widget.activity!.location;
      categoryController.text = _capitalize(widget.activity!.category);
      _selectedDate = widget.activity!.time;
      _selectedTime = TimeOfDay.fromDateTime(widget.activity!.time);
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void _saveActivity() async {
    if (titleController.text.isEmpty) return;
    if (categoryController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Defina uma categoria para organizar sua mala!")),
      );
      return;
    }

    final DateTime combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final activity = Activity(
      id: widget.activity?.id ?? '',
      tripId: widget.tripId,
      title: titleController.text,
      time: combinedDateTime,
      location: locationController.text,
      category: categoryController.text.trim().toLowerCase(),
      votes: widget.activity?.votes ?? {},
      opinions: widget.activity?.opinions ?? [],
      isApproved: widget.activity?.isApproved ?? true,
      description: widget.activity?.description,
      latitude: widget.activity?.latitude,
      longitude: widget.activity?.longitude,
    );

    try {
      if (widget.activity == null) {
        await _controller.addActivity(activity);
      } else {
        await _controller.updateActivity(activity);
      }

      // Agenda o Alarme para 15 minutos ANTES da atividade
      final scheduledTime = combinedDateTime.subtract(const Duration(minutes: 15));
      
      if (scheduledTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: combinedDateTime.millisecondsSinceEpoch.remainder(100000),
          title: "Sua atividade começa em breve! ✈️",
          body: "Prepare as coisas, '${activity.title}' em ${activity.location} começa em 15 minutos.",
          scheduledDate: scheduledTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.activity == null 
                ? "Atividade salva! Categoria '${_capitalize(activity.category)}' criada e vinculada ao checklist." 
                : "Atividade atualizada!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.activity != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Atividade" : "Adicionar Atividade"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "O que você vai fazer?",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Localização / Endereço",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 25),
            
            const Text(
              "Criar Nova Categoria para Bagagem",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Nome da Categoria",
                hintText: "Ex: Mergulho, Noite Gala, Esqui...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            const Text(
              "Dica: O nome que você digitar aqui aparecerá como uma nova seção no seu Checklist de Bagagem.",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 25),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text("Data e Horário"),
                subtitle: Text("${_selectedDate.day}/${_selectedDate.month} às ${_selectedTime.format(context)}"),
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveActivity,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  isEditing ? "ATUALIZAR NO ROTEIRO" : "SALVAR NO ROTEIRO", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Atividade?"),
        content: const Text("Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await _controller.deleteActivity(widget.activity!.id);
              if (mounted) {
                Navigator.pop(context); // fecha dialog
                Navigator.pop(context); // volta para roteiro
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
