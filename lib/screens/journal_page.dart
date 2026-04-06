import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';
import 'create_journal_entry_page.dart';

class JournalPage extends StatelessWidget {
  final String tripId;
  const JournalPage({super.key, required this.tripId});

  // Função para compartilhar o Link do Álbum em Tempo Real
  Future<void> _shareLiveAlbumLink(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    
    // Este link deve apontar para a versão web do seu app que exibe o diário
    final String albumUrl = "https://travel-app-etec.web.app/journal/$tripId";
    
    final String message = "📸 Acompanhe meu Diário de Viagem em tempo real!\n\n"
        "Estou postando fotos e relatos da nossa viagem aqui neste álbum:\n"
        "$albumUrl\n\n"
        "Fique de olho para ver as novidades! ✈️🌍";

    await Share.share(
      message,
      subject: "Álbum de Viagem em Tempo Real",
      sharePositionOrigin: box != null 
          ? box.localToGlobal(Offset.zero) & box.size 
          : null,
    );
  }

  Future<void> _shareSingleEntry(JournalEntry entry, BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    String text = "📸 Registro de Viagem (${DateFormat('dd/MM').format(entry.date)}):\n\n"
        "${entry.content}\n\n"
        "Veja mais no meu diário: https://travel-app-etec.web.app/journal/$tripId";

    await Share.share(
      text,
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TripController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Diário de Viagem"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (btnContext) => IconButton(
              icon: const Icon(Icons.ios_share), // Ícone corrigido de share_arrival para ios_share
              tooltip: "Compartilhar Link do Álbum",
              onPressed: () => _shareLiveAlbumLink(btnContext),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
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

          final entries = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Card Informativo no Topo
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blueGrey[700]!, Colors.blueGrey[400]!]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                          SizedBox(width: 10),
                          Text("Álbum em Tempo Real", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Compartilhe o link deste diário para que amigos e família acompanhem suas fotos e relatos ao vivo!",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      Builder(
                        builder: (btnContext) => ElevatedButton.icon(
                          onPressed: () => _shareLiveAlbumLink(btnContext),
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text("COMPARTILHAR LINK DO ÁLBUM"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey[800],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (entries.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_stories, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text("Seu diário está vazio.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildMemoryCard(context, entries[index]),
                      childCount: entries.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, JournalEntry entry) {
    return GestureDetector(
      onTap: () => _showEntryDetails(context, entry),
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.photos.isNotEmpty)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.network(
                  entry.photos.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM, yyyy').format(entry.date),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 16),
                      ),
                      Row(
                        children: [
                          _buildMoodIndicator(entry.moodScore),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (btnContext) => IconButton(
                              icon: const Icon(Icons.share, size: 20, color: Colors.blueGrey),
                              onPressed: () => _shareSingleEntry(entry, btnContext),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                  ),
                  if (entry.locationName != null && entry.locationName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(entry.locationName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMMM').format(entry.date),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        _buildMoodIndicator(entry.moodScore),
                      ],
                    ),
                    const Divider(height: 30),
                    
                    if (entry.photos.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry.photos.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                entry.photos[index],
                                width: 280,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 25),
                    Text(
                      entry.content,
                      style: const TextStyle(fontSize: 18, height: 1.6),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIndicator(double score) {
    IconData icon;
    Color color;
    if (score >= 4.5) { icon = Icons.sentiment_very_satisfied; color = Colors.green; }
    else if (score >= 3.5) { icon = Icons.sentiment_satisfied; color = Colors.blue; }
    else if (score >= 2.5) { icon = Icons.sentiment_neutral; color = Colors.amber; }
    else { icon = Icons.sentiment_dissatisfied; color = Colors.orange; }
    return Icon(icon, color: color, size: 28);
  }
}
