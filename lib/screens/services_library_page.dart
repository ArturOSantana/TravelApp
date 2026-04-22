import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';
import 'add_recommendation_page.dart';

class ServicesLibraryPage extends StatefulWidget {
  final String? tripId;
  const ServicesLibraryPage({super.key, this.tripId});

  @override
  State<ServicesLibraryPage> createState() => _ServicesLibraryPageState();
}

class _ServicesLibraryPageState extends State<ServicesLibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  final List<String> _categories = [
    'Todas',
    'Hospedagem',
    'Restaurante',
    'Transporte',
    'Passeio',
    'Serviço',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Comunidade"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(170),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
                tabs: const [
                  Tab(text: "Feed", icon: Icon(Icons.groups_outlined)),
                  Tab(text: "Meus posts", icon: Icon(Icons.person_outline)),
                  Tab(text: "Salvos", icon: Icon(Icons.bookmark_border)),
                ],
              ),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsList(type: 'community'),
          _buildPostsList(type: 'personal'),
          _buildPostsList(type: 'saved'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddRecommendationPage(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo post'),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar por local ou categoria...",
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList({required String type}) {
    Stream<List<ServiceModel>> stream;
    if (type == 'saved') {
      stream = _controller.getSavedServices();
    } else if (type == 'personal') {
      stream = _controller.getPersonalServices();
    } else {
      stream = _controller.getCommunityServices();
    }

    return StreamBuilder<List<ServiceModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = (snapshot.data ?? []).where((post) {
          final query = _searchQuery;
          final matchesSearch = post.name.toLowerCase().contains(query) ||
              post.location.toLowerCase().contains(query) ||
              post.category.toLowerCase().contains(query);

          final matchesCategory = _selectedCategory == 'Todas' ||
              post.category.toLowerCase() == _selectedCategory.toLowerCase();

          return matchesSearch && matchesCategory;
        }).toList();

        if (posts.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(post: posts[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Nenhum post encontrado.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPostCard({required ServiceModel post}) {
    final bool isLiked = post.likes.contains(_currentUid);
    final bool isSaved = post.savedBy.contains(_currentUid);
    final bool isOwner = post.ownerId == _currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPostDetails(post),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.photos.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(post.photos.first, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(post.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                      if (isOwner) 
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmDeletePost(post),
                        ),
                    ],
                  ),
                  Text('${post.category} • ${post.location}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(post.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _iconStat(Icons.favorite, isLiked ? Colors.red : Colors.grey, '${post.likes.length}'),
                      const SizedBox(width: 15),
                      _iconStat(Icons.comment_outlined, Colors.grey, '${post.comments.length}'),
                      const Spacer(),
                      IconButton(icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.amber : Colors.grey), 
                        onPressed: () => _controller.toggleSaveService(post.id, post.savedBy)),
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

  Widget _iconStat(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showPostDetails(ServiceModel initialPost) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('services').doc(initialPost.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final post = ServiceModel.fromFirestore(snapshot.data!);

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
                      Text(post.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("${post.category} • ${post.location}", style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 15),
                      if (post.photos.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.photos.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(post.photos[i], width: 280, fit: BoxFit.cover)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(post.comment, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const Divider(height: 40),
                      Text("Comentários (${post.comments.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      if (post.comments.isEmpty)
                        const Text("Ainda não há comentários.", style: TextStyle(color: Colors.grey))
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
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: "Diga algo legal...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              final text = commentController.text.trim();
                              commentController.clear();
                              await _controller.addServiceComment(post.id, post.comments, text);
                            }
                          },
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
              CircleAvatar(radius: 15, backgroundColor: Colors.indigo[50], child: Text(c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'V', style: const TextStyle(fontSize: 10, color: Colors.indigo))),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15), bottomLeft: Radius.circular(15))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(c.text),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 4),
            child: Text(DateFormat('dd/MM HH:mm').format(c.createdAt), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(ServiceModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Post"),
        content: const Text("Tem certeza?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await _controller.deleteService(post.id, post.ownerId);
  }
}
