import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';
import '../services/memory_manager_service.dart';
import '../widgets/optimized_image.dart';
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
    final String albumUrl =
        "https://travel-app-tcc.web.app/journal/${widget.tripId}";
    final String message =
        "Confira o meu álbum de memórias da viagem!\n$albumUrl";

    await Share.share(
      message,
      subject: "Álbum de Viagem",
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text(
            "Registros da Viagem",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Semantics(
            label: "Compartilhar álbum de viagem",
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareLiveAlbumLink(context),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Semantics(
              label: "Filtrar registros por localização",
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar por localização...",
                  prefixIcon: const Icon(Icons.search_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: "Adicionar novo registro ou foto à viagem",
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).colorScheme.primary,
          label: const Text(
            "NOVO REGISTRO",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateJournalEntryPage(tripId: widget.tripId),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: controller.getJournalEntries(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final entries = (snapshot.data ?? [])
              .where(
                (e) =>
                    (e.locationName ?? '').toLowerCase().contains(_searchQuery),
              )
              .toList();

          if (entries.isEmpty) return _buildEmptyState();

          final memoryManager = MemoryManagerService();
          final pageSize = memoryManager.getOptimalPageSize();

          // Carrega apenas os primeiros itens para dispositivos leves
          final displayEntries =
              memoryManager.isLowEndDevice && entries.length > pageSize
                  ? entries.take(pageSize).toList()
                  : entries;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayEntries.length +
                (memoryManager.isLowEndDevice && entries.length > pageSize
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index >= displayEntries.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Mostrando ${displayEntries.length} de ${entries.length} registros',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return _buildAlbumEntry(context, displayEntries[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumEntry(BuildContext context, JournalEntry entry) {
    return Semantics(
      label:
          "Registro de ${entry.userName} em ${entry.locationName ?? 'Local não definido'}. Data: ${DateFormat('dd/MM/yyyy').format(entry.date)}",
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildMoodTag(entry.mood),
                ],
              ),
            ),
            if (entry.photos.isNotEmpty)
              ClipRRect(
                child: entry.photos.length == 1
                    ? _buildImage(
                        entry.photos.first,
                        entry.locationName,
                        height: 300,
                      )
                    : _buildImageGallery(entry.photos, entry.locationName),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.locationName ?? "Localização não informada",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReactionBar(entry),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(entry.date),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String photoData, String? location, {double? height}) {
    // Suporte híbrido: Base64 (antigo) e URL (novo Storage)
    final bool isBase64 = !photoData.startsWith('http');

    return Semantics(
      label: "Foto registrada em ${location ?? 'viagem'}",
      child: isBase64
          ? Image.memory(
              base64Decode(photoData),
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              cacheWidth: MemoryManagerService().isLowEndDevice ? 800 : null,
              errorBuilder: (_, __, ___) => _errorImage(),
            )
          : OptimizedImage(
              imageUrl: photoData,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorWidget: _errorImage(),
            ),
    );
  }

  Widget _buildImageGallery(List<String> photos, String? location) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: _buildImage(photos[index], location, height: 250),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTag(MoodIcon mood) {
    IconData iconData;
    Color color;
    String label;

    switch (mood) {
      case MoodIcon.veryHappy:
        iconData = Icons.sentiment_very_satisfied;
        color = Colors.green;
        label = "Muito Feliz";
        break;
      case MoodIcon.happy:
        iconData = Icons.sentiment_satisfied;
        color = Colors.lightGreen;
        label = "Feliz";
        break;
      case MoodIcon.neutral:
        iconData = Icons.sentiment_neutral;
        color = Colors.amber;
        label = "Neutro";
        break;
      case MoodIcon.sad:
        iconData = Icons.sentiment_dissatisfied;
        color = Colors.orange;
        label = "Triste";
        break;
      case MoodIcon.verySad:
        iconData = Icons.sentiment_very_dissatisfied;
        color = Colors.red;
        label = "Muito Triste";
        break;
    }

    return Semantics(
      label: "Humor registrado: $label",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            "Nenhum registro encontrado.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _errorImage() => Container(
        height: 200,
        color: Colors.grey[100],
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );

  Widget _buildReactionBar(JournalEntry entry) {
    final controller = TripController();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReactionButton(
            entry,
            ReactionType.like,
            Icons.favorite,
            Colors.red,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.love,
            Icons.favorite_border,
            Colors.pink,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.wow,
            Icons.star,
            Colors.amber,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.celebrate,
            Icons.celebration,
            Colors.orange,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.support,
            Icons.thumb_up,
            Colors.blue,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.thanks,
            Icons.volunteer_activism,
            Colors.purple,
            controller,
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(
    JournalEntry entry,
    ReactionType reactionType,
    IconData icon,
    Color color,
    TripController controller,
  ) {
    final reactionKey = reactionType.toString().split('.').last;
    final count = entry.reactions[reactionKey]?.length ?? 0;
    final hasReacted = entry.hasUserReacted(reactionKey);

    return Semantics(
      label: "Reagir com ${reactionType.label}. $count reações",
      button: true,
      child: InkWell(
        onTap: () async {
          await controller.addReactionToJournalEntry(
            tripId: widget.tripId,
            entryId: entry.id,
            reactionType: reactionType,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: hasReacted ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasReacted ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: hasReacted ? color : Colors.grey),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasReacted ? color : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
