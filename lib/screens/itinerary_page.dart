import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import 'create_activity_page.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text("Roteiro da Viagem", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildActivityList()),
        ],
      ),
      floatingActionButton: Semantics(
        label: "Adicionar nova atividade ao roteiro",
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateActivityPage(tripId: widget.tripId))),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<String>>(
      stream: _controller.watchTripCategories(widget.tripId),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? ['Todos'];
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<List<Activity>>(
      stream: _controller.getActivities(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allActivities = snapshot.data!;
        final activities = _selectedCategory == 'Todos' 
          ? allActivities 
          : allActivities.where((a) => a.category == _selectedCategory).toList();

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("Nenhuma atividade encontrada."),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity, index);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(Activity activity, int index) {
    return Semantics(
      label: "Atividade: ${activity.title} às ${DateFormat('HH:mm').format(activity.time)} em ${activity.location}",
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
          ),
          title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${DateFormat('dd/MM HH:mm').format(activity.time)} • ${activity.location}"),
          trailing: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
      ),
    );
  }
}
