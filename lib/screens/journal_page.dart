import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';
import '../services/memory_manager_service.dart';
import '../theme/travel_colors.dart';
import '../theme/travel_spacing.dart';
import '../theme/travel_text_styles.dart';
import '../widgets/core/travel_widgets.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareLiveAlbumLink(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;

    final String albumUrl =
        "https://travel-app-tcc.web.app/album?tripId=${widget.tripId}";
    final String message = "Confira o álbum de memórias da viagem!\n$albumUrl";

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
      backgroundColor: TravelColors.cloudWhite,
      appBar: TravelAppBar.standard(
        title: "Registros da Viagem",
        actions: [
          Semantics(
            label: "Compartilhar álbum de viagem",
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareLiveAlbumLink(context),
              tooltip: "Compartilhar álbum",
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(TravelSpacing.md),
            child: TravelTextField.search(
              controller: _searchController,
              hint: "Buscar por localização...",
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: "Adicionar novo registro ou foto à viagem",
        child: FloatingActionButton.extended(
          backgroundColor: TravelColors.sunsetOrange,
          foregroundColor: TravelColors.cloudWhite,
          label: const Text(
            "Novo Registro",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: TravelLoadingIndicator());
          }

          if (snapshot.hasError) {
            return TravelEmptyState.error(
              errorMessage: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final entries = (snapshot.data ?? [])
              .where(
                (e) =>
                    (e.locationName ?? '').toLowerCase().contains(_searchQuery),
              )
              .toList();

          if (entries.isEmpty) {
            return _searchQuery.isNotEmpty
                ? TravelEmptyState.noSearchResults(searchTerm: _searchQuery)
                : TravelEmptyState.noJournalEntries(
                    onCreateEntry: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateJournalEntryPage(tripId: widget.tripId),
                      ),
                    ),
                  );
          }

          final memoryManager = MemoryManagerService();
          final pageSize = memoryManager.getOptimalPageSize();

          final displayEntries =
              memoryManager.isLowEndDevice && entries.length > pageSize
                  ? entries.take(pageSize).toList()
                  : entries;

          return ListView.builder(
            padding: EdgeInsets.all(TravelSpacing.md),
            itemCount: displayEntries.length +
                (memoryManager.isLowEndDevice && entries.length > pageSize
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index >= displayEntries.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(TravelSpacing.md),
                    child: Text(
                      'Mostrando ${displayEntries.length} de ${entries.length} registros',
                      style: TravelTextStyles.bodySmall(context).copyWith(
                        color: TravelColors.stoneGray,
                      ),
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
      child: TravelCard.standard(
        margin: EdgeInsets.only(bottom: TravelSpacing.lg),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com usuário e mood
            Padding(
              padding: EdgeInsets.all(TravelSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TravelColors.skyBlueLight.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: TravelColors.skyBlue,
                    ),
                  ),
                  SizedBox(width: TravelSpacing.sm),
                  Expanded(
                    child: Text(
                      entry.userName,
                      style: TravelTextStyles.titleSmall(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildMoodTag(entry.mood),
                ],
              ),
            ),

            // Galeria de fotos
            if (entry.photos.isNotEmpty)
              entry.photos.length == 1
                  ? _buildImage(
                      entry.photos.first,
                      entry.locationName,
                      height: 300,
                    )
                  : _buildImageGallery(entry.photos, entry.locationName),

            // Conteúdo
            Padding(
              padding: EdgeInsets.all(TravelSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Localização
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: TravelColors.error,
                      ),
                      SizedBox(width: TravelSpacing.xs),
                      Expanded(
                        child: Text(
                          entry.locationName ?? "Localização não informada",
                          style: TravelTextStyles.labelMedium(context).copyWith(
                            color: TravelColors.stoneGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: TravelSpacing.sm),

                  // Texto do registro
                  Text(
                    entry.content,
                    style: TravelTextStyles.bodyMedium(context),
                  ),

                  SizedBox(height: TravelSpacing.md),

                  // Barra de reações
                  _buildReactionBar(entry),

                  SizedBox(height: TravelSpacing.sm),

                  // Data
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(entry.date),
                    style: TravelTextStyles.labelSmall(context),
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
    final bool isBase64 = !photoData.startsWith('http');

    return Semantics(
      label: "Foto registrada em ${location ?? 'viagem'}",
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
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
          padding: EdgeInsets.only(right: TravelSpacing.xs),
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
        color = TravelColors.success;
        label = "Muito Feliz";
        break;
      case MoodIcon.happy:
        iconData = Icons.sentiment_satisfied;
        color = TravelColors.forestGreen;
        label = "Feliz";
        break;
      case MoodIcon.neutral:
        iconData = Icons.sentiment_neutral;
        color = TravelColors.sandBeige;
        label = "Neutro";
        break;
      case MoodIcon.sad:
        iconData = Icons.sentiment_dissatisfied;
        color = TravelColors.warning;
        label = "Triste";
        break;
      case MoodIcon.verySad:
        iconData = Icons.sentiment_very_dissatisfied;
        color = TravelColors.error;
        label = "Muito Triste";
        break;
    }

    return Semantics(
      label: "Humor registrado: $label",
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: TravelSpacing.sm,
          vertical: TravelSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TravelSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 16, color: color),
            SizedBox(width: TravelSpacing.xs),
            Text(
              label,
              style: TravelTextStyles.labelSmall(context).copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorImage() => Container(
        height: 200,
        color: TravelColors.stoneGrayLight.withOpacity(0.3),
        child: Icon(
          Icons.broken_image_outlined,
          color: TravelColors.stoneGray,
          size: 48,
        ),
      );

  Widget _buildReactionBar(JournalEntry entry) {
    final controller = TripController();

    return Container(
      padding: EdgeInsets.symmetric(vertical: TravelSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TravelColors.stoneGrayLight),
          bottom: BorderSide(color: TravelColors.stoneGrayLight),
        ),
      ),
      child: Wrap(
        spacing: TravelSpacing.sm,
        runSpacing: TravelSpacing.sm,
        children: [
          _buildReactionButton(
            entry,
            ReactionType.like,
            Icons.favorite,
            TravelColors.error,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.love,
            Icons.favorite_border,
            TravelColors.sunsetOrange,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.wow,
            Icons.star,
            TravelColors.sandBeige,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.celebrate,
            Icons.celebration,
            TravelColors.sunsetOrange,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.support,
            Icons.thumb_up,
            TravelColors.skyBlue,
            controller,
          ),
          _buildReactionButton(
            entry,
            ReactionType.thanks,
            Icons.volunteer_activism,
            TravelColors.forestGreen,
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
        borderRadius: BorderRadius.circular(TravelSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: TravelSpacing.sm,
            vertical: TravelSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: hasReacted ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(TravelSpacing.radiusLg),
            border: Border.all(
              color: hasReacted ? color : TravelColors.stoneGrayLight,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: hasReacted ? color : TravelColors.stoneGray,
              ),
              if (count > 0) ...[
                SizedBox(width: TravelSpacing.xs),
                Text(
                  count.toString(),
                  style: TravelTextStyles.labelSmall(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasReacted ? color : TravelColors.stoneGray,
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

// Made with Bob
