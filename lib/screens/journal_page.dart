import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';
import 'create_journal_entry_page.dart';

class JournalPage extends StatelessWidget {
  final String tripId;
  const JournalPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Diário de Viagem"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateJournalEntryPage(tripId: tripId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: controller.getJournalEntries(tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar diário: \${snapshot.error}"));
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("Nenhuma memória registrada ainda.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("Comece a escrever seu diário!"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(entry.date),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          _buildMoodIndicator(entry.moodScore),
                        ],
                      ),
                      const Divider(),
                      if (entry.locationName != null && entry.locationName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(entry.locationName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      Text(
                        entry.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (entry.photos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: entry.photos.length,
                              itemBuilder: (context, pIndex) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    entry.photos[pIndex], 
                                    width: 100, 
                                    height: 100, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMoodIndicator(double score) {
    IconData icon;
    Color color;
    if (score >= 4.5) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (score >= 3.5) {
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
    } else if (score >= 2.5) {
      icon = Icons.sentiment_neutral;
      color = Colors.amber;
    } else if (score >= 1.5) {
      icon = Icons.sentiment_dissatisfied;
      color = Colors.orange;
    } else {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    }
    return Icon(icon, color: color);
  }
}
