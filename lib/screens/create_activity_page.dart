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
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  void _saveActivity() async {
    if (titleController.text.isEmpty) return;

    final DateTime combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final activity = Activity(
      id: '', // Firestore gerará o ID
      tripId: widget.tripId,
      title: titleController.text,
      time: combinedDateTime,
      location: locationController.text,
    );

    // 1. Salva no banco
    await _controller.addActivity(activity);

    // 2. Agenda o Alarme/Notificação (REVOLUCIONÁRIO!)
    await NotificationService.scheduleNotification(
      combinedDateTime.millisecondsSinceEpoch.remainder(100000), // ID único simples
      "Lembrete de Viagem: \${activity.title}",
      "Sua atividade em \${activity.location} começa agora!",
      combinedDateTime,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Atividade")),
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
            const SizedBox(height: 20),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Localização / Endereço",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              title: const Text("Data e Horário"),
              subtitle: Text("\${_selectedDate.day}/\${_selectedDate.month} às \${_selectedTime.format(context)}"),
              leading: const Icon(Icons.calendar_today),
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

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, 
                  foregroundColor: Colors.white
                ),
                onPressed: _saveActivity,
                child: const Text("Salvar no Roteiro"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
