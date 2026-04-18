import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      titleController.text = widget.activity!.title;
      locationController.text = widget.activity!.location;
      categoryController.text = _capitalize(widget.activity!.category);
      _selectedDate = widget.activity!.time;
      _selectedTime = TimeOfDay.fromDateTime(widget.activity!.time);
      _lat = widget.activity!.latitude;
      _lon = widget.activity!.longitude;
    }
  }

  Future<List<Map<String, dynamic>>> _searchLocations(String query) async {
    if (query.length < 3) return [];
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&accept-language=pt-BR'),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': double.tryParse(item['lat']),
          'lon': double.tryParse(item['lon']),
        }).toList();
      }
    } catch (e) {
      debugPrint("Erro na busca de locais: $e");
    }
    return [];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void _saveActivity() async {
    if (titleController.text.isEmpty) return;
    if (categoryController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Defina uma categoria!")),
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
      latitude: _lat,
      longitude: _lon,
    );

    try {
      if (widget.activity == null) {
        await _controller.addActivity(activity);
      } else {
        await _controller.updateActivity(activity);
      }

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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
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
            
            SearchAnchor(
              builder: (BuildContext context, SearchController searchController) {
                return TextFormField(
                  controller: locationController,
                  readOnly: true,
                  onTap: () => searchController.openView(),
                  decoration: const InputDecoration(
                    labelText: "Localização / Endereço",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    suffixIcon: Icon(Icons.search),
                  ),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController searchController) async {
                final results = await _searchLocations(searchController.text);
                return results.map((loc) => ListTile(
                  leading: const Icon(Icons.place, color: Colors.deepPurple),
                  title: Text(loc['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    setState(() {
                      locationController.text = loc['display_name'];
                      _lat = loc['lat'];
                      _lon = loc['lon'];
                    });
                    searchController.closeView(loc['display_name']);
                  },
                )).toList();
              },
            ),
            
            const SizedBox(height: 20),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Categoria",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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
                    final time = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (time != null) setState(() { _selectedDate = date; _selectedTime = time; });
                  }
                },
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saveActivity,
                child: const Text("SALVAR ATIVIDADE", style: TextStyle(fontWeight: FontWeight.bold)),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () async {
            await _controller.deleteActivity(widget.activity!.id);
            if (mounted) { Navigator.pop(context); Navigator.pop(context); }
          }, child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
