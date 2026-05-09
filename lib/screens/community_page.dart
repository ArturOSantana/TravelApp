import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/destination_rating.dart';
import '../models/community_item.dart';
import '../controllers/trip_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_recommendation_page.dart';
import 'dart:async';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'todos';
  final TextEditingController _searchController = TextEditingController();
  final TripController _controller = TripController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late TabController _tabController;

  static const List<DropdownMenuItem<String>> _filterOptions = [
    DropdownMenuItem(value: 'todos', child: Text('Todos os tipos')),
    DropdownMenuItem(value: 'service', child: Text('Somente serviços')),
    DropdownMenuItem(
        value: 'destination_rating', child: Text('Somente avaliações')),
    DropdownMenuItem(value: 'com_foto', child: Text('Com foto')),
    DropdownMenuItem(value: 'sem_foto', child: Text('Sem foto')),
  ];

  // Streams combinados
  StreamSubscription? _servicesSubscription;
  StreamSubscription? _ratingsSubscription;
  List<CommunityItem> _allItems = [];
  List<CommunityItem> _myItems = [];
  List<CommunityItem> _savedItems = [];
  Set<String> _savedPostIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _markAsRead();
    _loadCommunityData();
    _loadSavedPosts();
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_viewed_post', DateTime.now().millisecondsSinceEpoch);
  }

  void _loadCommunityData() {
    // Escuta serviços públicos
    _servicesSubscription =
        _controller.getCommunityServices().listen((services) {
      _updateItems(services: services);
    });

    // Escuta avaliações de destino públicas
    _ratingsSubscription =
        _controller.getCommunityDestinationRatings().listen((ratings) {
      _updateItems(ratings: ratings);
    });
  }

  Future<void> _loadSavedPosts() async {
    try {
      final savedData = await _controller.getSavedPosts();
      final services = savedData['services'] as List<ServiceModel>;
      final ratings = savedData['ratings'] as List<DestinationRating>;

      setState(() {
        _savedItems = [
          ...services.map((s) => CommunityService(s)),
          ...ratings.map((r) => CommunityDestinationRating(r)),
        ];
        _savedItems.sort((a, b) => a.compareTo(b));

        // Atualiza set de IDs salvos
        _savedPostIds = {
          ...services.map((s) => 'service_${s.id}'),
          ...ratings.map((r) => 'rating_${r.id}'),
        };
      });
    } catch (e) {
      debugPrint('Erro ao carregar posts salvos: $e');
    }
  }

  void _updateItems(
      {List<ServiceModel>? services, List<DestinationRating>? ratings}) {
    setState(() {
      List<CommunityItem> allServices =
          services?.map((s) => CommunityService(s)).toList() ??
              _allItems.where((item) => item.type == 'service').toList();

      List<CommunityItem> allRatings = ratings
              ?.map((r) => CommunityDestinationRating(r))
              .toList() ??
          _allItems.where((item) => item.type == 'destination_rating').toList();

      _allItems = [...allServices, ...allRatings];
      _allItems.sort((a, b) => a.compareTo(b));

      // Filtra meus itens
      _myItems =
          _allItems.where((item) => item.ownerId == _currentUid).toList();

      _isLoading = false;
    });
  }

  Future<void> _toggleSavePost(String postId, String postType) async {
    final savedPostId = '${postType}_$postId';
    final isSaved = _savedPostIds.contains(savedPostId);

    try {
      if (isSaved) {
        await _controller.unsavePost(postId, postType);
      } else {
        await _controller.savePost(postId, postType);
      }

      // Recarrega posts salvos
      await _loadSavedPosts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Post removido dos salvos' : 'Post salvo!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar/dessalvar post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar post'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _servicesSubscription?.cancel();
    _ratingsSubscription?.cancel();
    super.dispose();
  }

  Future<String> _getUserName(String ownerId, String? currentUserName) async {
    if (currentUserName != null &&
        currentUserName.isNotEmpty &&
        currentUserName != 'Viajante') {
      return currentUserName;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Viajante';
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome do usuário: $e');
    }

    return 'Viajante';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecommendationPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Postagem'),
        tooltip: 'Criar nova recomendação',
      ),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text("Comunidade",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(168),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Semantics(
                  label: "Campo de busca na comunidade",
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar destino, categoria ou descrição...",
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filtro',
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: _filterOptions,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedFilter = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Meus Posts'),
                  Tab(text: 'Salvos'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPostsList(_allItems),
                _buildPostsList(_myItems),
                _buildPostsList(_savedItems),
              ],
            ),
    );
  }

  Widget _buildPostsList(List<CommunityItem> items) {
    final filteredItems = items.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          (item.userName ?? '').toLowerCase().contains(q);

      final matchesFilter = switch (_selectedFilter) {
        'service' => item.type == 'service',
        'destination_rating' => item.type == 'destination_rating',
        'com_foto' => item.photos.isNotEmpty,
        'sem_foto' => item.photos.isEmpty,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("Nenhum post encontrado",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) =>
          _buildPostCard(context, filteredItems[index]),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityItem item) {
    final bool isLiked = item.likes.contains(_currentUid);
    final bool isDestinationRating = item.type == 'destination_rating';
    final String savedPostId = '${item.type}_${item.id}';
    final bool isSaved = _savedPostIds.contains(savedPostId);

    return Semantics(
      button: true,
      label: "Post sobre ${item.title}. Toque para ver detalhes.",
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: InkWell(
          onTap: () => _showDetails(context, item),
          borderRadius: BorderRadius.circular(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.photos.isNotEmpty)
                Stack(
                  children: [
                    Semantics(
                      label: "Foto de ${item.title}",
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25)),
                        child: Image.network(item.photos.first,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        label: isSaved ? "Remover dos salvos" : "Salvar post",
                        button: true,
                        child: Material(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _toggleSavePost(item.id, item.type),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(item.title,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.photos.isEmpty)
                              Semantics(
                                label: isSaved
                                    ? "Remover dos salvos"
                                    : "Salvar post",
                                button: true,
                                child: IconButton(
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () =>
                                      _toggleSavePost(item.id, item.type),
                                ),
                              ),
                            if (item.ownerId == _currentUid)
                              PopupMenuButton<String>(
                                tooltip: 'Ações do post',
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await _confirmDeletePost(item);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline),
                                        SizedBox(width: 8),
                                        Text('Excluir'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: isDestinationRating
                                      ? Colors.purple.withOpacity(0.1)
                                      : Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Icon(
                                    isDestinationRating
                                        ? Icons.travel_explore
                                        : Icons.recommend,
                                    size: 12,
                                    color: isDestinationRating
                                        ? Colors.purple
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDestinationRating ? 'Viagem' : 'Serviço',
                                    style: TextStyle(
                                        color: isDestinationRating
                                            ? Colors.purple
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.subtitle,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13)),
                    const SizedBox(height: 12),
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4)),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(item.ownerId, item.userName),
                          builder: (context, snapshot) {
                            final displayName =
                                snapshot.data ?? item.userName ?? 'Viajante';
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(Icons.person,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!isDestinationRating)
                          Row(
                            children: [
                              Semantics(
                                button: true,
                                label: isLiked
                                    ? "Descurtir. ${item.likes.length} curtidas"
                                    : "Curtir. ${item.likes.length} curtidas",
                                child: InkWell(
                                  onTap: () {
                                    if (item is CommunityService) {
                                      _controller.toggleLikeService(
                                          item.service.id, item.service.likes);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 18,
                                            color: isLiked
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text('${item.likes.length}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (item is CommunityService) ...[
                                const SizedBox(width: 20),
                                _iconStat(
                                    Icons.comment_outlined,
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    '${item.service.comments.length}',
                                    "comentários"),
                              ],
                            ],
                          ),
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

  Widget _iconStat(
      IconData icon, Color color, String count, String semanticLabel) {
    return Semantics(
      label: "$count $semanticLabel",
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(count,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(CommunityItem item) async {
    final label =
        item.type == 'destination_rating' ? 'esta avaliação' : 'esta postagem';

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir conteúdo'),
            content: Text('Deseja realmente excluir $label?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      if (item is CommunityService) {
        await _controller.deleteService(item.service.id, item.service.ownerId);
      } else if (item is CommunityDestinationRating) {
        await _controller.deleteDestinationRating(
            item.rating.id, item.rating.userId);
      }

      await _loadSavedPosts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conteúdo excluído com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir conteúdo: $e')),
      );
    }
  }

  void _showDetails(BuildContext context, CommunityItem item) {
    if (item is CommunityService) {
      _showServiceDetails(context, item.service);
    } else if (item is CommunityDestinationRating) {
      _showDestinationRatingDetails(context, item.rating);
    }
  }

  void _showServiceDetails(BuildContext context, ServiceModel initialPost) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .doc(initialPost.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final post = ServiceModel.fromFirestore(snapshot.data!);
            final bool isLiked = post.likes.contains(_currentUid);

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                children: [
                  Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10))),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Semantics(
                                    header: true,
                                    child: Text(post.name,
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)))),
                            Semantics(
                              label: isLiked
                                  ? "Descurtir recomendação"
                                  : "Curtir recomendação",
                              child: IconButton(
                                icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    size: 28),
                                onPressed: () {
                                  _controller.toggleLikeService(
                                      post.id, post.likes);
                                },
                              ),
                            ),
                          ],
                        ),
                        Text("${post.category} • ${post.location}",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(Icons.person,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Por ${post.userName ?? 'Viajante'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(post.photos[i],
                                          width: 280, fit: BoxFit.cover)),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(post.comment,
                            style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const Divider(height: 40),
                        Semantics(
                            header: true,
                            child: Text("Comentários (${post.comments.length})",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(height: 15),
                        if (post.comments.isEmpty)
                          Center(
                              child: Text(
                            "Ainda não há comentários.",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ))
                        else
                          ...post.comments.reversed
                              .map((c) => _buildCommentBalloon(c)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 8, 16,
                        20 + MediaQuery.of(context).viewInsets.bottom),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        )),
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
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: "Enviar comentário",
                          child: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: IconButton(
                              icon: Icon(Icons.send,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  size: 20),
                              onPressed: () async {
                                if (commentController.text.trim().isNotEmpty) {
                                  final text = commentController.text.trim();
                                  commentController.clear();
                                  await _controller.addServiceComment(
                                      post.id, post.comments, text);
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
          }),
    );
  }

  void _showDestinationRatingDetails(
      BuildContext context, DestinationRating rating) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Icon(Icons.travel_explore,
                          size: 32, color: Colors.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(rating.destinationName,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.overallRating.toStringAsFixed(1)}/5.0',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.person,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Por ${rating.userName ?? 'Viajante'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(rating.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (rating.photos.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: rating.photos.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(rating.photos[i],
                                  width: 280, fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (rating.review != null && rating.review!.isNotEmpty) ...[
                    const Text('Comentário:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(rating.review!,
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                  const SizedBox(height: 20),
                  const Text('Avaliações Detalhadas:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRatingRow('Custo-Benefício', rating.valueForMoney),
                  _buildRatingRow('Acessibilidade', rating.accessibility),
                  _buildRatingRow('Movimento', rating.crowdLevel),
                  _buildRatingRow('Segurança', rating.safety),
                  if (rating.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Tags:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rating.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.purple.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, double? value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < value.round() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${value.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
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
              CircleAvatar(
                  radius: 16,
                  child: Text(c.userName.isNotEmpty
                      ? c.userName[0].toUpperCase()
                      : 'V')),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        c.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 4),
            child: Text(DateFormat('dd/MM HH:mm').format(c.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}

// Made with Bob
