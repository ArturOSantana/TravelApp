import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    
    // Agora usando as funções corretas do TripController
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showPostDetails(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName ?? 'Viajante', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${post.category} • ${post.location}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isOwner) 
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeletePost(post),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(post.comment, maxLines: 3, overflow: TextOverflow.ellipsis),
              if (post.photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(post.photos.first, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                    onPressed: () => _controller.toggleLikeService(post.id, post.likes),
                  ),
                  Text('${post.likes.length}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.amber : Colors.grey),
                    onPressed: () => _controller.toggleSaveService(post.id, post.savedBy),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => Share.share("Confira: ${post.name}\n${post.comment}"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetails(ServiceModel post) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(post.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(post.comment),
                  const Divider(height: 30),
                  const Text("Comentários", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...post.comments.map((c) => ListTile(
                    title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text(c.text),
                  )),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(hintText: "Escreva um comentário..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (commentController.text.isNotEmpty) {
                      await _controller.addServiceComment(post.id, post.comments, commentController.text);
                      commentController.clear();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(ServiceModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Post"),
        content: const Text("Tem certeza que deseja apagar este post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.deleteService(post.id, post.ownerId);
    }
  }
}
