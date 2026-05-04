import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/destination_rating.dart';
import '../services/storage_service.dart';

class RateDestinationPage extends StatefulWidget {
  final String tripId;
  final String activityId;
  final String destinationName;

  const RateDestinationPage({
    super.key,
    required this.tripId,
    required this.activityId,
    required this.destinationName,
  });

  @override
  State<RateDestinationPage> createState() => _RateDestinationPageState();
}

class _RateDestinationPageState extends State<RateDestinationPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _userName =
      FirebaseAuth.instance.currentUser?.displayName ?? 'Viajante';

  double _overallRating = 3.0;
  double _valueForMoney = 3.0;
  double _accessibility = 3.0;
  double _crowdLevel = 3.0;
  double _safety = 3.0;

  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<File> _selectedPhotos = [];
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Destino'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.destinationName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRatingSection(
                    'Avaliação Geral',
                    _overallRating,
                    (value) => setState(() => _overallRating = value),
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildRatingSection(
                    'Custo-Benefício',
                    _valueForMoney,
                    (value) => setState(() => _valueForMoney = value),
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildRatingSection(
                    'Acessibilidade',
                    _accessibility,
                    (value) => setState(() => _accessibility = value),
                    Icons.accessible,
                    Colors.blue,
                  ),
                  _buildRatingSection(
                    'Nível de Lotação',
                    _crowdLevel,
                    (value) => setState(() => _crowdLevel = value),
                    Icons.people,
                    Colors.orange,
                  ),
                  _buildRatingSection(
                    'Segurança',
                    _safety,
                    (value) => setState(() => _safety = value),
                    Icons.security,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Comentário',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reviewController,
                            maxLines: 5,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Conte sobre sua experiência...',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: RatingTags.all.map((tag) {
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
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Fotos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _pickPhotos,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Adicionar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_selectedPhotos.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedPhotos.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(
                                                _selectedPhotos[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () =>
                                                _selectedPhotos.removeAt(index),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: SwitchListTile(
                      title: const Text('Compartilhar na Comunidade'),
                      subtitle: const Text(
                        'Outros viajantes poderão ver sua avaliação',
                      ),
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submitRating,
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'Enviar Avaliação',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingSection(
    String title,
    double value,
    Function(double) onChanged,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 8,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
                activeColor: color,
              ),
            ),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _pickPhotos() async {
    final photos = await StorageService.pickMultipleImages();
    if (photos.isNotEmpty) {
      setState(() => _selectedPhotos.addAll(photos));
    }
  }

  Future<void> _submitRating() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, escreva um comentário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload das fotos
      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        photoUrls = await StorageService.uploadMultiplePhotos(
          photos: _selectedPhotos,
          tripId: widget.tripId,
          folder: 'ratings',
          onProgress: (current, total) {
            print('Uploading photo $current of $total');
          },
        );
      }

      // Salvar avaliação
      await _db.collection('destination_ratings').add({
        'tripId': widget.tripId,
        'activityId': widget.activityId,
        'userId': _userId,
        'userName': _userName,
        'destinationName': widget.destinationName,
        'overallRating': _overallRating,
        'valueForMoney': _valueForMoney,
        'accessibility': _accessibility,
        'crowdLevel': _crowdLevel,
        'safety': _safety,
        'review': _reviewController.text,
        'tags': _selectedTags,
        'photos': photoUrls,
        'visitDate': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'isPublic': _isPublic,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avaliação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
