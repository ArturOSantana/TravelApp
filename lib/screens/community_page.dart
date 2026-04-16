import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TripController _controller = TripController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          "Feed da Comunidade",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar posts, locais ou categorias...",
                prefixIcon: const Icon(Icons.search_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _controller.getCommunityServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPosts = snapshot.data ?? [];
          final posts =
              allPosts.where((post) {
                final name = post.name.toLowerCase();
                final loc = post.location.toLowerCase();
                final cat = post.category.toLowerCase();
                final text = post.comment.toLowerCase();

                return name.contains(_searchQuery) ||
                    loc.contains(_searchQuery) ||
                    cat.contains(_searchQuery) ||
                    text.contains(_searchQuery);
              }).toList()..sort((a, b) {
                final bDate = b.updatedAt ?? b.lastUsed;
                final aDate = a.updatedAt ?? a.lastUsed;
                return bDate.compareTo(aDate);
              });

          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, post);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty
                  ? Icons.forum_outlined
                  : Icons.search_off_outlined,
              size: 80,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isEmpty
                  ? "Nenhum post publicado ainda."
                  : "Nenhum post encontrado.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? "Assim que a comunidade começar a publicar, os posts aparecerão aqui."
                  : "Tente buscar por outro termo.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ServiceModel post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.photos.isNotEmpty)
              Image.network(
                post.photos.first,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 170,
                width: double.infinity,
                color: Colors.grey[100],
                child: const Icon(
                  Icons.image_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.location,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey[100],
                        child: const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (post.userName ?? '').trim().isNotEmpty
                              ? post.userName!.trim()
                              : 'Viajante',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes.length}'),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.mode_comment_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.comments.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, ServiceModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${post.category} • ${post.location}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[100],
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Publicado por',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              (post.userName ?? '').trim().isNotEmpty
                                  ? post.userName!.trim()
                                  : 'Viajante',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (post.photos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              post.photos[index],
                              width: 290,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Text(
                      "Conteúdo do post",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post.comment,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildInfoChip(
                          Icons.favorite_border,
                          '${post.likes.length} curtidas',
                        ),
                        _buildInfoChip(
                          Icons.mode_comment_outlined,
                          '${post.comments.length} comentários',
                        ),
                        _buildInfoChip(
                          Icons.payments_outlined,
                          'R\$ ${post.averageCost.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Comentários da comunidade",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (post.comments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Ainda não há comentários visíveis neste post.',
                        ),
                      )
                    else
                      ...post.comments.map(
                        (comment) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: comment.isHidden
                              ? Text(
                                  'Comentário ocultado pelo autor do post.',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment.text),
                                  ],
                                ),
                        ),
                      ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => Share.share(
                          "Confira este post da comunidade no Travel App:\n\n"
                          "${post.name}\n"
                          "${post.category} • ${post.location}\n\n"
                          "${post.comment}",
                        ),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text(
                          "COMPARTILHAR POST",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

// Made with Bob
