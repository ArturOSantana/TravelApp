import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_rating.dart';
import '../controllers/trip_controller.dart';

class RatePlacePage extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String placeAddress;
  final double? placeLat;
  final double? placeLon;
  final String placeCategory;
  final String? tripId;
  final PlaceRating? existingRating; // Para edição

  const RatePlacePage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    this.placeLat,
    this.placeLon,
    required this.placeCategory,
    this.tripId,
    this.existingRating,
  });

  @override
  State<RatePlacePage> createState() => _RatePlacePageState();
}

class _RatePlacePageState extends State<RatePlacePage> {
  final TripController _controller = TripController();
  final TextEditingController _reviewController = TextEditingController();

  double _overallRating = 3.0;
  double? _foodQuality;
  double? _serviceQuality;
  double? _valueForMoney;
  double? _cleanliness;
  double? _atmosphere;

  List<String> _selectedTags = [];
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _loadExistingRating();
    }
  }

  void _loadExistingRating() {
    final rating = widget.existingRating!;
    setState(() {
      _overallRating = rating.overallRating;
      _foodQuality = rating.foodQuality;
      _serviceQuality = rating.serviceQuality;
      _valueForMoney = rating.valueForMoney;
      _cleanliness = rating.cleanliness;
      _atmosphere = rating.atmosphere;
      _reviewController.text = rating.review ?? '';
      _selectedTags = List.from(rating.tags);
      _isPublic = rating.isPublic;
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _saveRating() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final rating = PlaceRating(
        id: widget.existingRating?.id ?? '',
        userId: user.uid,
        userName: user.displayName ?? 'Viajante',
        placeId: widget.placeId,
        placeName: widget.placeName,
        placeAddress: widget.placeAddress,
        placeLat: widget.placeLat,
        placeLon: widget.placeLon,
        placeCategory: widget.placeCategory,
        overallRating: _overallRating,
        foodQuality: _foodQuality,
        serviceQuality: _serviceQuality,
        valueForMoney: _valueForMoney,
        cleanliness: _cleanliness,
        atmosphere: _atmosphere,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        tags: _selectedTags,
        createdAt: widget.existingRating?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: _isPublic,
        tripId: widget.tripId,
        likes: widget.existingRating?.likes ?? [],
        helpfulCount: widget.existingRating?.helpfulCount ?? 0,
      );

      if (widget.existingRating != null) {
        await _controller.updatePlaceRating(rating);
      } else {
        await _controller.addPlaceRating(rating);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRating != null
                ? 'Avaliação atualizada com sucesso!'
                : 'Avaliação publicada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTags = PlaceTags.getTagsForCategory(widget.placeCategory);
    final isRestaurant =
        widget.placeCategory.toLowerCase().contains('restaurant') ||
            widget.placeCategory.toLowerCase().contains('cafe') ||
            widget.placeCategory.toLowerCase().contains('food');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRating != null
            ? 'Editar Avaliação'
            : 'Avaliar Lugar'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRating,
              tooltip: 'Salvar avaliação',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do lugar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(widget.placeCategory),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.placeName,
                                style: const TextStyle(
                                  fontSize: 18,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Avaliação geral
            Text(
              'Avaliação Geral',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildRatingSlider(
              'Nota geral',
              _overallRating,
              (value) => setState(() => _overallRating = value),
              Icons.star,
            ),
            const SizedBox(height: 24),

            // Critérios específicos
            Text(
              'Critérios Detalhados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            if (isRestaurant) ...[
              _buildOptionalRatingSlider(
                'Qualidade da comida',
                _foodQuality,
                (value) => setState(() => _foodQuality = value),
                Icons.restaurant_menu,
              ),
            ],

            _buildOptionalRatingSlider(
              'Atendimento',
              _serviceQuality,
              (value) => setState(() => _serviceQuality = value),
              Icons.support_agent,
            ),

            _buildOptionalRatingSlider(
              'Custo-benefício',
              _valueForMoney,
              (value) => setState(() => _valueForMoney = value),
              Icons.attach_money,
            ),

            _buildOptionalRatingSlider(
              'Limpeza',
              _cleanliness,
              (value) => setState(() => _cleanliness = value),
              Icons.cleaning_services,
            ),

            _buildOptionalRatingSlider(
              'Ambiente',
              _atmosphere,
              (value) => setState(() => _atmosphere = value),
              Icons.wb_sunny,
            ),

            const SizedBox(height: 24),

            // Review
            Text(
              'Sua Opinião',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Conte sua experiência neste lugar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            // Tags
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Privacidade
            SwitchListTile(
              title: const Text('Tornar avaliação pública'),
              subtitle: const Text('Outros usuários poderão ver sua avaliação'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildStarRating(value),
                const SizedBox(width: 8),
                Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalRatingSlider(
    String label,
    double? value,
    ValueChanged<double?> onChanged,
    IconData icon,
  ) {
    final isActive = value != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isActive ? null : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isActive ? null : Colors.grey,
                    ),
                  ),
                ),
                if (isActive) ...[
                  _buildStarRating(value!),
                  const SizedBox(width: 8),
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                Switch(
                  value: isActive,
                  onChanged: (enabled) {
                    onChanged(enabled ? 3.0 : null);
                  },
                ),
              ],
            ),
            if (isActive)
              Slider(
                value: value!,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: value.toStringAsFixed(1),
                onChanged: (newValue) => onChanged(newValue),
              ),
          ],
        ),
      ),
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

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurant') ||
        cat.contains('cafe') ||
        cat.contains('food')) {
      return Icons.restaurant;
    } else if (cat.contains('entertainment') || cat.contains('leisure')) {
      return Icons.celebration;
    } else {
      return Icons.attractions;
    }
  }
}

// Made with Bob
