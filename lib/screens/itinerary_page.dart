import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../controllers/trip_controller.dart';
import 'create_activity_page.dart';

class ItineraryPage extends StatelessWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
              int upVotes = activity.votes.values.where((v) => v == 1).length;
              int downVotes = activity.votes.values.where((v) => v == -1).length;
              int myVote = activity.votes[uid] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    child: Text("${activity.time.hour}:${activity.time.minute.toString().padLeft(2, '0')}", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ),
                  title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(activity.location),
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("O grupo concorda?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Text("$upVotes", style: const TextStyle(color: Colors.green)),
                                  IconButton(
                                    icon: Icon(Icons.thumb_up, color: myVote == 1 ? Colors.green : Colors.grey, size: 20),
                                    onPressed: () => controller.voteActivity(activity.id, uid, 1),
                                  ),
                                  Text("$downVotes", style: const TextStyle(color: Colors.red)),
                                  IconButton(
                                    icon: Icon(Icons.thumb_down, color: myVote == -1 ? Colors.red : Colors.grey, size: 20),
                                    onPressed: () => controller.voteActivity(activity.id, uid, -1),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Opiniões do Grupo:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ...activity.opinions.map((op) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(op['userName'] ?? 'Viajante', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            subtitle: Text(op['text'] ?? ''),
                          )).toList(),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: "Dê sua opinião...",
                              hintStyle: TextStyle(fontSize: 12),
                              suffixIcon: Icon(Icons.send, size: 18),
                            ),
                            onSubmitted: (val) {
                              if (val.isNotEmpty) {
                                controller.addOpinion(activity.id, val);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
