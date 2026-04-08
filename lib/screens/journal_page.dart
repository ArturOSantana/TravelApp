import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';
import 'create_journal_entry_page.dart';

class JournalPage extends StatefulWidget {
  final String tripId;
  const JournalPage({super.key, required this.tripId});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _shareLiveAlbumLink(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final String albumUrl = "https://travel-app-tcc.web.app/journal/${widget.tripId}";
    
    final String message = "Confira o meu álbum de fotos e memórias da viagem!\n\n"
        "Acesse pelo link:\n"
        "$albumUrl";

    await Share.share(
      message,
      subject: "Álbum de Viagem",
      sharePositionOrigin: box != null 
          ? box.localToGlobal(Offset.zero) & box.size 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Álbum de Viagem", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: "Compartilhar Álbum",
            onPressed: () => _shareLiveAlbumLink(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Filtrar por localização...",
                prefixIcon: const Icon(Icons.search_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_outlined),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        label: const Text("ADICIONAR FOTO", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateJournalEntryPage(tripId: widget.tripId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: controller.getJournalEntries(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEntries = snapshot.data ?? [];
          final entries = allEntries.where((entry) {
            final loc = entry.locationName?.toLowerCase() ?? '';
            return loc.contains(_searchQuery);
          }).toList();

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty ? "Seu álbum está vazio." : "Nenhuma memória encontrada.",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _searchQuery.isEmpty ? "Registre suas memórias de viagem." : "Tente outro termo de busca.",
                    style: const TextStyle(color: Colors.grey)
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _buildAlbumEntry(context, entries[index]),
          );
        },
      ),
    );
  }

  Widget _buildAlbumEntry(BuildContext context, JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(entry.date),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                if (entry.locationName != null && entry.locationName!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.locationName!,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (entry.photos.isNotEmpty)
            ClipRRect(
              child: entry.photos.length == 1
                  ? _buildBase64Image(entry.photos.first, height: 250)
                  : _buildImageGrid(entry.photos),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.content,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildMoodTag(entry.moodScore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64Image(String base64String, {double? height}) {
    try {
      Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorImage(),
      );
    } catch (e) {
      return _errorImage();
    }
  }

  Widget _errorImage() {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }

  Widget _buildImageGrid(List<String> base64Urls) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: base64Urls.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: _buildBase64Image(base64Urls[index], height: 250),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTag(double score) {
    String label;
    IconData icon;
    Color color;

    if (score >= 4.5) { label = "Incrível"; icon = Icons.sentiment_very_satisfied_outlined; color = Colors.green; }
    else if (score >= 3.5) { label = "Bom"; icon = Icons.sentiment_satisfied_outlined; color = Colors.blue; }
    else if (score >= 2.5) { label = "Ok"; icon = Icons.sentiment_neutral_outlined; color = Colors.amber; }
    else { label = "Cansativo"; icon = Icons.sentiment_dissatisfied_outlined; color = Colors.orange; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
