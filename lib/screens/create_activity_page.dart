import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import '../services/notification_service.dart';

class CreateActivityPage extends StatefulWidget {
  final String tripId;
  final Activity? activity;
  final String? suggestedName;
  final String? suggestedLocation;
  final double? suggestedLat;
  final double? suggestedLon;

  const CreateActivityPage({
    super.key,
    required this.tripId,
    this.activity,
    this.suggestedName,
    this.suggestedLocation,
    this.suggestedLat,
    this.suggestedLon,
  });

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
    } else if (widget.suggestedName != null) {
      // Preencher com dados sugeridos
      titleController.text = widget.suggestedName!;
      locationController.text = widget.suggestedLocation ?? '';
      _lat = widget.suggestedLat;
      _lon = widget.suggestedLon;
    }
  }

  Future<List<Map<String, dynamic>>> _searchLocations(String query) async {
    if (query.length < 3) return [];
    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&accept-language=pt-BR'),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => {
                  'display_name': item['display_name'],
                  'lat': double.tryParse(item['lat']),
                  'lon': double.tryParse(item['lon']),
                })
            .toList();
      }
    } catch (e) {
      debugPrint("Erro na busca de locais: $e");
    }
    return [];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

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

      final scheduledTime =
          combinedDateTime.subtract(const Duration(minutes: 15));
      if (scheduledTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: combinedDateTime.millisecondsSinceEpoch.remainder(100000),
          title: "Sua atividade começa em breve! ✈️",
          body:
              "Prepare as coisas, '${activity.title}' em ${activity.location} começa em 15 minutos.",
          scheduledDate: scheduledTime,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.activity != null ? "Editar Atividade" : "Nova Atividade"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: "Campo para o título da atividade",
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "O que você vai fazer?",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: "Campo para buscar localização da atividade",
              child: SearchAnchor(
                builder:
                    (BuildContext context, SearchController searchController) {
                  return TextFormField(
                    controller: locationController,
                    readOnly: true,
                    onTap: () => searchController.openView(),
                    decoration: const InputDecoration(
                      labelText: "Onde? (Localização)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      suffixIcon: Icon(Icons.search),
                    ),
                  );
                },
                suggestionsBuilder: (BuildContext context,
                    SearchController searchController) async {
                  final results = await _searchLocations(searchController.text);
                  return results
                      .map((loc) => ListTile(
                            leading: const Icon(Icons.place,
                                color: Colors.deepPurple),
                            title: Text(loc['display_name'],
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              setState(() {
                                locationController.text = loc['display_name'];
                                _lat = loc['lat'];
                                _lon = loc['lon'];
                              });
                              searchController.closeView(loc['display_name']);
                            },
                          ))
                      .toList();
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Categoria (Ex: Jantar, Passeio)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 30),
            const Text("Quando?",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPickerCard(
                    label: "Data",
                    value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                    icon: Icons.calendar_today,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildPickerCard(
                    label: "Hora",
                    value: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveActivity,
                child: const Text("SALVAR ATIVIDADE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCard(
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return Semantics(
      button: true,
      label: "Selecionar $label. Valor atual: $value",
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
