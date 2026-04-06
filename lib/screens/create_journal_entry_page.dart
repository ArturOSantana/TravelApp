import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';

class CreateJournalEntryPage extends StatefulWidget {
  final String tripId;
  const CreateJournalEntryPage({super.key, required this.tripId});

  @override
  State<CreateJournalEntryPage> createState() => _CreateJournalEntryPageState();
}

class _CreateJournalEntryPageState extends State<CreateJournalEntryPage> {
  final _controller = TripController();
  final _contentController = TextEditingController();
  double _moodScore = 3.0;

  void _saveEntry() async {
    if (_contentController.text.isEmpty) return;

    final entry = JournalEntry(
      id: '',
      tripId: widget.tripId,
      date: DateTime.now(),
      content: _contentController.text,
      moodScore: _moodScore,
      createdAt: DateTime.now(),
    );

    await _controller.addJournalEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova Memória")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Como você está se sentindo hoje?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _moodScore,
              min: 1,
              max: 5,
              divisions: 4,
              label: _moodScore.round().toString(),
              onChanged: (val) => setState(() => _moodScore = val),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: "Escreva aqui sua experiência do dia...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                onPressed: _saveEntry,
                child: const Text("Registrar no Diário"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
