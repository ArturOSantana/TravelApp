import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_viewed_post', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text("Comunidade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Semantics(
              label: "Campo de busca na comunidade",
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar destino ou categoria...",
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
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

          final posts = (snapshot.data ?? []).where((post) {
            final q = _searchQuery.toLowerCase();
            return post.name.toLowerCase().contains(q) ||
                post.location.toLowerCase().contains(q) ||
                post.category.toLowerCase().contains(q);
          }).toList();

          if (posts.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                const Text("Nenhum post encontrado", style: TextStyle(color: Colors.grey)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) => _buildPostCard(context, posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ServiceModel post) {
    final bool isLiked = post.likes.contains(_currentUid);

    return Semantics(
      button: true,
      label: "Post sobre ${post.name} em ${post.location}. Toque para ver detalhes.",
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: InkWell(
          onTap: () => _showDetails(context, post),
          borderRadius: BorderRadius.circular(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.photos.isNotEmpty)
                Semantics(
                  label: "Foto de ${post.name}",
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: Image.network(post.photos.first, height: 200, width: double.infinity, fit: BoxFit.cover),
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
                        Expanded(child: Text(post.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(post.category, style: const TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(post.location, style: const TextStyle(color: Colors.black54, fontSize: 13)), // Cor ajustada para contraste WCAG
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(post.comment, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, height: 1.4)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                        const SizedBox(width: 8),
                        Text(post.userName ?? 'Viajante', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const Spacer(),
                        _iconStat(Icons.favorite, isLiked ? Colors.red : Colors.grey[400]!, '${post.likes.length}', "curtidas"),
                        const SizedBox(width: 15),
                        _iconStat(Icons.comment_outlined, Colors.grey[400]!, '${post.comments.length}', "comentários"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconStat(IconData icon, Color color, String count, String semanticLabel) {
    return Semantics(
      label: "$count $semanticLabel",
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, ServiceModel initialPost) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('services').doc(initialPost.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final post = ServiceModel.fromFirestore(snapshot.data!);
          final bool isLiked = post.likes.contains(_currentUid);

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(
              children: [
                Container(width: 50, height: 5, margin: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Semantics(header: true, child: Text(post.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
                          Semantics(
                            label: isLiked ? "Descurtir recomendação" : "Curtir recomendação",
                            child: IconButton(
                              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 28),
                              onPressed: () => _controller.toggleLikeService(post.id, post.likes),
                            ),
                          ),
                        ],
                      ),
                      Text("${post.category} • ${post.location}", style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      if (post.photos.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.photos.length,
                            itemBuilder: (context, i) => Semantics(
                              label: "Foto detalhada de ${post.name}",
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(post.photos[i], width: 280, fit: BoxFit.cover)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(post.comment, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                      const Divider(height: 40),
                      Semantics(header: true, child: Text("Comentários (${post.comments.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 15),
                      if (post.comments.isEmpty)
                        const Center(child: Text("Ainda não há comentários.", style: TextStyle(color: Colors.black54)))
                      else
                        ...post.comments.reversed.map((c) => _buildCommentBalloon(c)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: "Campo para escrever comentário",
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: "Adicione um comentário...",
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        button: true,
                        label: "Enviar comentário",
                        child: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: () async {
                              if (commentController.text.trim().isNotEmpty) {
                                final text = commentController.text.trim();
                                commentController.clear();
                                await _controller.addServiceComment(post.id, post.comments, text);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildCommentBalloon(PostComment c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 16, child: Text(c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'V')),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(c.text, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 4),
            child: Text(DateFormat('dd/MM HH:mm').format(c.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
