import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import 'create_activity_page.dart';

class ItineraryPage extends StatelessWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Roteiro Inteligente"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateActivityPage(tripId: tripId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<Activity>>(
        stream: controller.getActivities(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("Seu roteiro está vazio.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("Adicione atividades para começar!"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    child: Text("${activity.time.hour}:${activity.time.minute.toString().padLeft(2, '0')}", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ),
                  title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(activity.location),
                  trailing: activity.votes.isNotEmpty 
                    ? const Icon(Icons.how_to_vote, color: Colors.orange) 
                    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
