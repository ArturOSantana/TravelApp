import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/trip_controller.dart';
import '../models/activity.dart';
import '../models/trip.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';
import 'create_activity_page.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TripController _controller = TripController();
  String? _weatherDescription;
  bool _isLoadingAI = false;
  List<String> _aiSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final trips = await _controller.getTrips().first;
      final trip = trips.where((item) => item.id == widget.tripId).firstOrNull;
      if (trip == null) return;

      final weather = await WeatherService.getWeather(trip.destination);
      if (mounted) {
        setState(() {
          _weatherDescription = weather?['desc']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar clima: $e");
    }
  }

  Future<void> _getAISuggestions(String dest) async {
    setState(() => _isLoadingAI = true);
    final suggestions = await AIService.getRoteiroSuggestions(dest);
    if (mounted) {
      setState(() {
        _aiSuggestions = suggestions;
        _isLoadingAI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Roteiro Inteligente"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova atividade'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateActivityPage(tripId: widget.tripId)));
        },
      ),
      body: StreamBuilder<List<Trip>>(
        stream: _controller.getTrips(),
        builder: (context, tripSnapshot) {
          final trip = (tripSnapshot.data ?? []).where((item) => item.id == widget.tripId).firstOrNull;
          if (trip == null) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
              _buildAIHeader(trip),
              Expanded(
                child: StreamBuilder<List<Activity>>(
                  stream: _controller.getActivities(widget.tripId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final activities = snapshot.data ?? [];

                    if (activities.isEmpty) {
                      return const Center(child: Text("Seu roteiro está vazio."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _buildActivityCard(activity, uid);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAIHeader(Trip trip) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple[700]!, Colors.deepPurple[400]!]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text("Sugestões da IA para você", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_weatherDescription != null)
                Text(_weatherDescription!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          if (_aiSuggestions.isEmpty)
            ElevatedButton(
              onPressed: () => _getAISuggestions(trip.destination),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
              child: _isLoadingAI 
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("GERAR SUGESTÕES PARA ESTE DESTINO"),
            )
          else
            Wrap(
              spacing: 8,
              children: _aiSuggestions.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.white.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.white),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, String uid) {
    int upVotes = activity.votes.values.where((v) => v == 1).length;
    int downVotes = activity.votes.values.where((v) => v == -1).length;
    int myVote = activity.votes[uid] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          child: Text("${activity.time.hour}:${activity.time.minute.toString().padLeft(2, '0')}", 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ),
        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(activity.location),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Opiniões do Grupo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...activity.opinions.map((op) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("${op['userName']}: ${op['text']}", style: const TextStyle(fontSize: 12)),
                )).toList(),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(hintText: "Adicionar comentário...", hintStyle: TextStyle(fontSize: 12)),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) _controller.addOpinion(activity.id, val);
                  },
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("$upVotes", style: const TextStyle(color: Colors.green)),
                    IconButton(icon: Icon(Icons.thumb_up, color: myVote == 1 ? Colors.green : Colors.grey, size: 18), 
                      onPressed: () => _controller.voteActivity(activity.id, uid, 1)),
                    Text("$downVotes", style: const TextStyle(color: Colors.red)),
                    IconButton(icon: Icon(Icons.thumb_down, color: myVote == -1 ? Colors.red : Colors.grey, size: 18), 
                      onPressed: () => _controller.voteActivity(activity.id, uid, -1)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
