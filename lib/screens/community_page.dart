import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
        title: const Text("Explorar Comunidade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Para onde você quer ir?",
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

    return Container(
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: Image.network(post.photos.first, height: 220, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text(post.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(post.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(post.comment, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: Colors.indigo[50], child: const Icon(Icons.person, size: 14, color: Colors.indigo)),
                      const SizedBox(width: 8),
                      Text(post.userName ?? 'Viajante', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const Spacer(),
                      _iconStat(Icons.favorite, isLiked ? Colors.red : Colors.grey[300]!, post.likes.length.toString()),
                      const SizedBox(width: 15),
                      _iconStat(Icons.mode_comment, Colors.grey[300]!, post.comments.length.toString()),
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

  Widget _iconStat(IconData icon, Color color, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
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
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
            child: Column(
              children: [
                Stack(
                  children: [
                    if (post.photos.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                        child: Image.network(post.photos.first, height: 250, width: double.infinity, fit: BoxFit.cover),
                      )
                    else
                      Container(height: 100, decoration: BoxDecoration(color: Colors.indigo[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(35)))),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(25),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(post.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 30),
                            onPressed: () => _controller.toggleLikeService(post.id, post.likes),
                          ),
                        ],
                      ),
                      Text(post.location, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 10,
                        children: [
                          _detailChip(Icons.star, Colors.amber, "${post.rating} / 5.0"),
                          _detailChip(Icons.payments, Colors.green, "R\$ ${post.averageCost.toStringAsFixed(2)}"),
                        ],
                      ),

                      const SizedBox(height: 25),
                      const Text("Dicas e Relato", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(post.comment, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.6)),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Divider(),
                      ),

                      Text("Comentários (${post.comments.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      if (post.comments.isEmpty)
                        Center(child: Text("Seja o primeiro a comentar!", style: TextStyle(color: Colors.grey[400])))
                      else
                        ...post.comments.reversed.map((c) => _buildCommentBalloon(c)),

                      const SizedBox(height: 100), 
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: "Diga algo legal...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton.small(
                        backgroundColor: Colors.indigo,
                        elevation: 0,
                        onPressed: () async {
                          if (commentController.text.trim().isNotEmpty) {
                            final text = commentController.text.trim();
                            commentController.clear();
                            await _controller.addServiceComment(post.id, post.comments, text);
                          }
                        },
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommentBalloon(PostComment c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16, 
            backgroundColor: Colors.indigo[50], 
            child: Text(c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'V', 
            style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold))
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], 
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(20))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(c.text, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 5),
                  child: Text(
                    DateFormat('dd/MM HH:mm').format(c.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
