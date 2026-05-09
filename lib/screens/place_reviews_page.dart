import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/place_rating.dart';
import '../controllers/trip_controller.dart';

class PlaceReviewsPage extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String placeAddress;

  const PlaceReviewsPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
  });

  @override
  State<PlaceReviewsPage> createState() => _PlaceReviewsPageState();
}

class _PlaceReviewsPageState extends State<PlaceReviewsPage> {
  final TripController _controller = TripController();
  PlaceStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _controller.getPlaceStats(widget.placeId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliações'),
      ),
      body: Column(
        children: [
          // Header com informações do lugar
          _buildPlaceHeader(),

          // Estatísticas
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_stats != null)
            _buildStatsSection(),

          const Divider(height: 1),

          // Lista de avaliações
          Expanded(
            child: StreamBuilder<List<PlaceRating>>(
              stream: _controller.getPlaceRatings(widget.placeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child:
                        Text('Erro ao carregar avaliações: ${snapshot.error}'),
                  );
                }

                final ratings = snapshot.data ?? [];

                if (ratings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma avaliação ainda',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a avaliar!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ratings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildReviewCard(ratings[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.placeName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.placeAddress,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nota geral
          Row(
            children: [
              Column(
                children: [
                  Text(
                    _stats!.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStarRating(_stats!.averageRating),
                  const SizedBox(height: 4),
                  Text(
                    '${_stats!.totalRatings} ${_stats!.totalRatings == 1 ? "avaliação" : "avaliações"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_stats!.averageFoodQuality != null)
                      _buildCriteriaBar('Comida', _stats!.averageFoodQuality!),
                    if (_stats!.averageServiceQuality != null)
                      _buildCriteriaBar(
                          'Atendimento', _stats!.averageServiceQuality!),
                    if (_stats!.averageValueForMoney != null)
                      _buildCriteriaBar(
                          'Custo-benefício', _stats!.averageValueForMoney!),
                    if (_stats!.averageCleanliness != null)
                      _buildCriteriaBar('Limpeza', _stats!.averageCleanliness!),
                    if (_stats!.averageAtmosphere != null)
                      _buildCriteriaBar('Ambiente', _stats!.averageAtmosphere!),
                  ],
                ),
              ),
            ],
          ),

          // Tags mais usadas
          if (_stats!.topTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stats!.topTags.map((tag) {
                final count = _stats!.tagCounts[tag] ?? 0;
                return Chip(
                  label: Text('$tag ($count)'),
                  avatar: const Icon(Icons.local_offer, size: 16),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 5.0,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(PlaceRating rating) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnReview = rating.userId == currentUserId;
    final hasLiked = rating.likes.contains(currentUserId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com usuário e nota
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    rating.userName[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(rating.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(rating.overallRating),
                const SizedBox(width: 4),
                Text(
                  rating.overallRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

          if (rating.review != null && rating.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rating.review!),
            ],

            if (rating.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rating.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Critérios detalhados
            if (rating.foodQuality != null ||
                rating.serviceQuality != null ||
                rating.valueForMoney != null ||
                rating.cleanliness != null ||
                rating.atmosphere != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (rating.foodQuality != null)
                    _buildCriteriaChip(
                        'Comida', rating.foodQuality!, Icons.restaurant_menu),
                  if (rating.serviceQuality != null)
                    _buildCriteriaChip('Atendimento', rating.serviceQuality!,
                        Icons.support_agent),
                  if (rating.valueForMoney != null)
                    _buildCriteriaChip('Custo-benefício', rating.valueForMoney!,
                        Icons.attach_money),
                  if (rating.cleanliness != null)
                    _buildCriteriaChip('Limpeza', rating.cleanliness!,
                        Icons.cleaning_services),
                  if (rating.atmosphere != null)
                    _buildCriteriaChip(
                        'Ambiente', rating.atmosphere!, Icons.wb_sunny),
                ],
              ),
            ],

            // Ações
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.red : null,
                  ),
                  onPressed: () async {
                    await _controller.toggleLikePlaceRating(
                        rating.id, rating.likes);
                  },
                ),
                Text('${rating.likes.length}'),
                const SizedBox(width: 16),
                Icon(Icons.thumb_up_outlined,
                    size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${rating.helpfulCount} útil',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (isOwnReview)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                    onPressed: () {
                    },
                  ),
                if (!isOwnReview)
                  TextButton(
                    onPressed: () async {
                      await _controller.markPlaceRatingAsHelpful(rating.id);
                    },
                    child: const Text('Marcar como útil'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaChip(String label, double value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 16, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
        }
      }),
    );
  }
}

