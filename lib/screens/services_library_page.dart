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
    _tabController = TabController(length: 3, vsync: this); // Alterado para 3 abas
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
                  Tab(text: "Meus posts", icon: Icon(Icons.person_outline)),
                  Tab(text: "Salvos", icon: Icon(Icons.bookmark_border)),
                  Tab(text: "Feed", icon: Icon(Icons.groups_outlined)),
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
          _buildPostsList(type: 'personal'),
          _buildPostsList(type: 'saved'),
          _buildPostsList(type: 'community'),
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
              hintText: "Buscar...",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
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
    if (type == 'community') {
      stream = _controller.getCommunityServices();
    } else if (type == 'saved') {
      stream = _controller.getSavedServices();
    } else {
      stream = _controller.getPersonalServices();
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
              post.category.toLowerCase().contains(query) ||
              post.comment.toLowerCase().contains(query);

          final matchesCategory = _selectedCategory == 'Todas' ||
              post.category.toLowerCase() == _selectedCategory.toLowerCase();

          return matchesSearch && matchesCategory;
        }).toList()
          ..sort((a, b) {
            final bDate = b.updatedAt ?? b.lastUsed;
            final aDate = a.updatedAt ?? a.lastUsed;
            return bDate.compareTo(aDate);
          });

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
    String title = 'Nenhum post encontrado.';
    String sub = 'Compartilhe dicas com a comunidade.';
    IconData icon = Icons.post_add_outlined;

    if (type == 'saved') {
      title = 'Você não tem posts salvos.';
      sub = 'Salve recomendações interessantes para vê-las aqui.';
      icon = Icons.bookmark_border;
    } else if (type == 'community') {
      title = 'Feed vazio.';
      icon = Icons.groups_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[350]),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard({required ServiceModel post}) {
    final bool isLiked = post.likes.contains(_currentUid);
    final bool isSaved = post.savedBy.contains(_currentUid);
    final bool isOwner = post.ownerId == _currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showPostDetails(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo[50],
                    child: const Icon(Icons.person, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (post.userName ?? 'Viajante').trim().isNotEmpty ? post.userName!.trim() : 'Viajante',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text('${post.category} • ${post.location}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isOwner) _buildOwnerMenu(post),
                ],
              ),
              const SizedBox(height: 14),
              Text(post.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(post.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.5)),
              if (post.photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(post.photos.first, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[700],
                    label: '${post.likes.length}',
                    onTap: () => _controller.toggleLikeService(post.id, post.likes),
                  ),
                  const SizedBox(width: 18),
                  _buildActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.comments.length}',
                    onTap: () => _showPostDetails(post),
                  ),
                  const SizedBox(width: 18),
                  _buildActionButton(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.amber[700] : Colors.grey[700],
                    label: '${post.savesCount}',
                    onTap: () => _controller.toggleSaveService(post.id, post.savedBy),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.indigo),
                    onPressed: () => _sharePost(post),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, Color? color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[700], size: 20),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildOwnerMenu(ServiceModel post) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditPostDialog(post);
        } else if (value == 'delete') {
          _confirmDeletePost(post);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.edit_outlined), title: Text('Editar')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Apagar')),
        ),
      ],
    );
  }

  void _showPostDetails(ServiceModel post) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.9,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(width: 52, height: 5, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.indigo[50], child: const Icon(Icons.person, color: Colors.indigo)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text((post.userName ?? 'Viajante').trim().isNotEmpty ? post.userName!.trim() : 'Viajante', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('${post.category} • ${post.location}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(post.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),
                            if (post.photos.isNotEmpty)
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.photos.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) => ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(post.photos[index], width: 280, fit: BoxFit.cover)),
                                ),
                              ),
                            const SizedBox(height: 18),
                            Text(post.comment, style: const TextStyle(fontSize: 16, height: 1.6)),
                            const SizedBox(height: 18),
                            const Text('Comentários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...post.comments.map((comment) => _buildCommentTile(post: post, comment: comment, isOwner: post.ownerId == _currentUid)),
                            const SizedBox(height: 18),
                            TextField(
                              controller: commentController,
                              decoration: InputDecoration(
                                hintText: 'Escreva um comentário...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send, color: Colors.indigo),
                                  onPressed: () async {
                                    await _controller.addServiceComment(post.id, post.comments, commentController.text);
                                    commentController.clear();
                                    Navigator.pop(context);
                                  },
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
          },
        );
      },
    );
  }

  Widget _buildCommentTile({required ServiceModel post, required PostComment comment, required bool isOwner}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.white, child: const Icon(Icons.person_outline, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(ServiceModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar post'),
        content: const Text('Tem certeza que deseja apagar este post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteService(post.id, post.ownerId);
    }
  }

  Future<void> _showEditPostDialog(ServiceModel post) async {
    final titleController = TextEditingController(text: post.name);
    final commentController = TextEditingController(text: post.comment);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: commentController, maxLines: 3, decoration: const InputDecoration(labelText: 'Comentário')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _controller.updateService(post.copyWith(name: titleController.text, comment: commentController.text));
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _sharePost(ServiceModel post) {
    SharePlus.instance.share(ShareParams(text: "Confira este post no Travel App: ${post.name}\n${post.comment}"));
  }
}
