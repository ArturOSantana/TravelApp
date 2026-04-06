import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
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
  final List<File> _selectedImages = [];
  final List<String> _uploadedUrls = [];
  bool _isUploading = false;
  double _moodScore = 3.0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Reduz o tamanho para o TCC
      maxWidth: 1200,
    );
    
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<String> _uploadFile(File file) async {
    String fileName = path.basename(file.path);
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('journal_photos')
        .child(widget.tripId)
        .child(DateTime.now().millisecondsSinceEpoch.toString() + '_' + fileName);
    
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _saveEntry() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escreva algo sobre sua memória!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Fazer upload de todas as imagens para o Firebase Storage
      List<String> urls = [];
      for (File image in _selectedImages) {
        String url = await _uploadFile(image);
        urls.add(url);
      }

      // 2. Salvar no Firestore
      final entry = JournalEntry(
        id: '',
        tripId: widget.tripId,
        date: DateTime.now(),
        content: _contentController.text,
        moodScore: _moodScore,
        photos: urls,
        createdAt: DateTime.now(),
      );

      await _controller.addJournalEntry(entry);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Memória"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Como foi o seu dia?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Slider(
                  value: _moodScore,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.blueGrey,
                  label: _moodScore.round().toString(),
                  onChanged: (val) => setState(() => _moodScore = val),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Descreva sua aventura...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Fotos da Memória", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showImageSourceActionSheet(context),
                      icon: const Icon(Icons.add_a_photo, size: 18),
                      label: const Text("Adicionar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_selectedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                        Text("Nenhuma foto selecionada", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _isUploading ? null : _saveEntry,
                    child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SALVAR NO DIARIO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text("Subindo suas fotos para a nuvem..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
