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
    _tabController = TabController(length: 2, vsync: this);
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
                tabs: const [
                  Tab(text: "Meus posts", icon: Icon(Icons.person_outline)),
                  Tab(
                    text: "Feed da comunidade",
                    icon: Icon(Icons.groups_outlined),
                  ),
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
          _buildPostsList(isCommunity: false),
          _buildPostsList(isCommunity: true),
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
              hintText: "Buscar por título, local, categoria ou texto...",
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase().trim()),
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

  Widget _buildPostsList({required bool isCommunity}) {
    return StreamBuilder<List<ServiceModel>>(
      stream: isCommunity
          ? _controller.getCommunityServices()
          : _controller.getPersonalServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts =
            (snapshot.data ?? []).where((post) {
              final query = _searchQuery;
              final matchesSearch =
                  post.name.toLowerCase().contains(query) ||
                  post.location.toLowerCase().contains(query) ||
                  post.category.toLowerCase().contains(query) ||
                  post.comment.toLowerCase().contains(query);

              final matchesCategory =
                  _selectedCategory == 'Todas' ||
                  post.category.toLowerCase() ==
                      _selectedCategory.toLowerCase();

              return matchesSearch && matchesCategory;
            }).toList()..sort((a, b) {
              final bDate = b.updatedAt ?? b.lastUsed;
              final aDate = a.updatedAt ?? a.lastUsed;
              return bDate.compareTo(aDate);
            });

        if (posts.isEmpty) {
          return _buildEmptyState(isCommunity);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) =>
              _buildPostCard(post: posts[index], isCommunity: isCommunity),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isCommunity) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCommunity ? Icons.forum_outlined : Icons.post_add_outlined,
              size: 72,
              color: Colors.grey[350],
            ),
            const SizedBox(height: 16),
            Text(
              isCommunity
                  ? 'Nenhum post encontrado na comunidade.'
                  : 'Você ainda não criou nenhum post.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCommunity
                  ? 'Compartilhe dicas, experiências e opiniões para iniciar o feed.'
                  : 'Crie um post para compartilhar uma experiência com a comunidade.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required ServiceModel post,
    required bool isCommunity,
  }) {
    final bool isLiked = post.likes.contains(_currentUid);
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
                          (post.userName ?? 'Viajante').trim().isNotEmpty
                              ? post.userName!.trim()
                              : 'Viajante',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${post.category} • ${post.location}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner) _buildOwnerMenu(post),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.comment,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5),
              ),
              if (post.photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    post.photos.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  InkWell(
                    onTap: isCommunity
                        ? () =>
                              _controller.toggleLikeService(post.id, post.likes)
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey[700],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.likes.length}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text('${post.comments.length}'),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text('${post.savesCount}'),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.indigo),
                    onPressed: () => _sharePost(post),
                    tooltip: 'Compartilhar post',
                  ),
                  if (isCommunity && !isOwner)
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_add_outlined,
                        color: Colors.indigo,
                      ),
                      tooltip: 'Salvar nas minhas postagens',
                      onPressed: () => _importPost(post),
                    ),
                ],
              ),
            ],
          ),
        ),
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
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar post'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Apagar post'),
          ),
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
        final isOwner = post.ownerId == _currentUid;

        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final visibleComments = post.comments;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.indigo[50],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (post.userName ?? 'Viajante')
                                                .trim()
                                                .isNotEmpty
                                            ? post.userName!.trim()
                                            : 'Viajante',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${post.category} • ${post.location}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner) _buildOwnerMenu(post),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              post.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (post.photos.isNotEmpty)
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.photos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        post.photos[index],
                                        width: 280,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 18),
                            Text(
                              post.comment,
                              style: const TextStyle(fontSize: 16, height: 1.6),
                            ),
                            const SizedBox(height: 18),
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
                                  Icons.bookmark_border,
                                  '${post.savesCount} salvamentos',
                                ),
                                _buildInfoChip(
                                  Icons.payments_outlined,
                                  'R\$ ${post.averageCost.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'Comentários',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (visibleComments.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'Ainda não há comentários neste post.',
                                ),
                              )
                            else
                              ...visibleComments.map(
                                (comment) => _buildCommentTile(
                                  post: post,
                                  comment: comment,
                                  isOwner: isOwner,
                                ),
                              ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: commentController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Escreva um comentário...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      sheetContext,
                                    );
                                    final navigator = Navigator.of(
                                      sheetContext,
                                    );

                                    try {
                                      await _controller.addServiceComment(
                                        post.id,
                                        post.comments,
                                        commentController.text,
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      commentController.clear();
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Comentário publicado.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) {
                                        return;
                                      }
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
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

  Widget _buildCommentTile({
    required ServiceModel post,
    required PostComment comment,
    required bool isOwner,
  }) {
    final hiddenText = comment.hiddenBy == _currentUid
        ? 'Comentário ocultado por você.'
        : 'Comentário ocultado pelo autor do post.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: const Icon(Icons.person_outline, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: comment.isHidden
                ? Text(
                    hiddenText,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.text),
                    ],
                  ),
          ),
          if (isOwner && !comment.isHidden)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined, size: 20),
              tooltip: 'Ocultar comentário',
              onPressed: () => _hideComment(post, comment),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
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

  Future<void> _hideComment(ServiceModel post, PostComment comment) async {
    try {
      await _controller.hideServiceComment(
        serviceId: post.id,
        ownerId: post.ownerId,
        commentId: comment.id,
        currentComments: post.comments,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário ocultado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDeletePost(ServiceModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar post'),
        content: const Text(
          'Tem certeza que deseja apagar este post? Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _controller.deleteService(post.id, post.ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post apagado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showEditPostDialog(ServiceModel post) async {
    final titleController = TextEditingController(text: post.name);
    final locationController = TextEditingController(text: post.location);
    final commentController = TextEditingController(text: post.comment);
    String selectedCategory = post.category;
    bool isPublic = post.isPublic;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar post'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do post',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  items: _categories
                      .where((c) => c != 'Todas')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setDialogState(
                    () => selectedCategory = value ?? selectedCategory,
                  ),
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Local'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo do post',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Post público'),
                  value: isPublic,
                  onChanged: (value) => setDialogState(() => isPublic = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await _controller.updateService(
        post.copyWith(
          name: titleController.text.trim(),
          location: locationController.text.trim(),
          comment: commentController.text.trim(),
          category: selectedCategory,
          isPublic: isPublic,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post atualizado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _sharePost(ServiceModel post) {
    final String text =
        "Confira este post da comunidade no Travel App:\n\n"
        "${post.name}\n"
        "${post.category} • ${post.location}\n\n"
        "${post.comment}";
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _importPost(ServiceModel post) async {
    try {
      await _controller.importService(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post salvo nas suas postagens.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao salvar post: $e")));
    }
  }
}

// Made with Bob
