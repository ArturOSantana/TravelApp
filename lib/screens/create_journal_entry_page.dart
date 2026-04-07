import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isUploading = false;
  double _moodScore = 3.0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
    );
    
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<String> _uploadFile(File file) async {
    // Nome do arquivo ultra-simples para evitar qualquer erro de caracteres no path
    String fileName = "journal_${DateTime.now().millisecondsSinceEpoch}.jpg";
    
    // Referência na pasta journal_photos
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('journal_photos')
        .child(fileName);
    
    // Converte o arquivo em bytes antes de subir (resolve muitos erros de [object-not-found])
    final bytes = await file.readAsBytes();

    // Upload usando putData
    UploadTask uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Aguarda a tarefa completar
    TaskSnapshot snapshot = await uploadTask;
    
    // Retorna a URL de download
    return await snapshot.ref.getDownloadURL();
  }

  void _saveEntry() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escreva algo sobre sua memória!")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> urls = [];
      
      // Upload das fotos uma por uma
      for (File image in _selectedImages) {
        String url = await _uploadFile(image);
        urls.add(url);
      }

      // Salva os dados no Firestore após o sucesso dos uploads
      final entry = JournalEntry(
        id: '',
        tripId: widget.tripId,
        date: DateTime.now(),
        content: _contentController.text.trim(),
        moodScore: _moodScore,
        photos: urls,
        createdAt: DateTime.now(),
      );

      await _controller.addJournalEntry(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memória salva com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        debugPrint("ERRO AO SALVAR: $e");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Erro ao salvar memória"),
            content: Text("Ocorreu um erro ao subir as fotos para o Firebase Storage.\n\n"
                "PASSO IMPORTANTE:\n"
                "Verifique se o seu Firebase Storage está com as regras de segurança abertas para gravação.\n\n"
                "Detalhe técnico: $e"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
                  onChanged: (val) => setState(() => _moodScore = val),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "O que você viveu hoje?",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Fotos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.add_a_photo, color: Colors.blueGrey, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_selectedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 4, top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 100, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                    child: const Center(child: Text("Nenhuma foto selecionada", style: TextStyle(color: Colors.grey))),
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
                    child: const Text("SALVAR NO DIÁRIO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("Subindo fotos para a nuvem...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
