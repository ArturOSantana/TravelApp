import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/journal_entry.dart';
import '../controllers/trip_controller.dart';

class CreateJournalEntryPage extends StatefulWidget {
  final String tripId;
  const CreateJournalEntryPage({super.key, required this.tripId});

  @override
  State<CreateJournalEntryPage> createState() => _CreateJournalEntryPageState();
}

class _CreateJournalEntryPageState extends State<CreateJournalEntryPage> {
  final _controller = TripController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isSaving = false;
  MoodIcon _selectedMood = MoodIcon.neutral;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality:
          25, // Qualidade baixa para não exceder o limite de 1MB do Firestore
      maxWidth: 600,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  // converte a imagem para uma String
  Future<String> _imageToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  void _saveEntry() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Adicione um comentário!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      List<String> base64Images = [];
      for (File image in _selectedImages) {
        String base64 = await _imageToBase64(image);
        base64Images.add(base64);
      }

      final user = FirebaseAuth.instance.currentUser;

      final entry = JournalEntry(
        id: '',
        tripId: widget.tripId,
        userId: user?.uid ?? '',
        userName: user?.displayName ?? 'Viajante',
        date: DateTime.now(),
        content: _contentController.text.trim(),
        mood: _selectedMood,
        photos: base64Images,
        locationName: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await _controller.addJournalEntry(entry);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nova Memória"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: "Localização",
                    prefixIcon: const Icon(Icons.pin_drop, color: Colors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Comentário...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildMoodSelector(),
                const SizedBox(height: 25),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _selectedImages[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("ADICIONAR FOTO"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "SALVAR NO ÁLBUM",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Como você está se sentindo?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MoodIcon.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getMoodIconData(mood.iconName),
                      size: isSelected ? 40 : 32,
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood.label.split(' ').last, // Pega só a última palavra
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getMoodIconData(String iconName) {
    switch (iconName) {
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'sentiment_neutral':
        return Icons.sentiment_neutral;
      case 'sentiment_dissatisfied':
        return Icons.sentiment_dissatisfied;
      case 'sentiment_very_dissatisfied':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
