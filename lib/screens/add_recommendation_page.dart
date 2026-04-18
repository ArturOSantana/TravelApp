import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/service_model.dart';
import '../controllers/trip_controller.dart';

class AddRecommendationPage extends StatefulWidget {
  const AddRecommendationPage({super.key});

  @override
  State<AddRecommendationPage> createState() => _AddRecommendationPageState();
}

class _AddRecommendationPageState extends State<AddRecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TripController();
  final ImagePicker _picker = ImagePicker();

  String name = '';
  String category = 'Restaurante';
  String location = '';
  double rating = 5.0;
  String comment = '';
  double averageCost = 0.0;
  bool isPublic = true;
  bool _isUploading = false;

  final List<String> photos = []; // Lista final de URLs (Web + Uploads)
  final List<File> _localImages = []; // Arquivos selecionados localmente
  final TextEditingController _photoUrlController = TextEditingController();

  final List<String> categories = [
    'Hospedagem',
    'Restaurante',
    'Transporte',
    'Passeio',
    'Serviço',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (image != null) {
      setState(() {
        _localImages.add(File(image.path));
      });
    }
  }

  Future<String> _uploadFile(File file) async {
    String fileName = path.basename(file.path);
    String uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('service_photos')
        .child(uid)
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _saveRecommendation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isUploading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;

        // 1. Fazer upload das imagens locais e obter URLs
        List<String> allPhotos = List.from(photos); 
        for (File img in _localImages) {
          String url = await _uploadFile(img);
          allPhotos.add(url);
        }

        final newService = ServiceModel(
          id: '',
          ownerId: user?.uid ?? '',
          userName: null, // O controller resolverá o nome corretamente
          name: name,
          category: category,
          location: location,
          rating: rating,
          comment: comment,
          averageCost: averageCost,
          lastUsed: DateTime.now(),
          isPublic: isPublic,
          photos: allPhotos,
        );

        await _controller.saveService(newService);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Recomendação publicada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Erro detalhado ao publicar: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao publicar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
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
        title: const Text("Nova Recomendação"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "O que você quer recomendar?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Nome do Local/Serviço",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Informe o nome" : null,
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: "Categoria",
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => category = value!),
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Localização (Cidade/País)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Informe a localização" : null,
                    onSaved: (value) => location = value!,
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Text(
                        "Sua Nota: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: rating,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: rating.toString(),
                          activeColor: Colors.indigo,
                          onChanged: (v) => setState(() => rating = v),
                        ),
                      ),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Custo Médio (R\$)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) =>
                        averageCost = double.tryParse(value!) ?? 0.0,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Sua Opinião / Dicas",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? "Escreva um comentário" : null,
                    onSaved: (value) => comment = value!,
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Fotos e Imagens",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Opção 1: URL
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _photoUrlController,
                          decoration: const InputDecoration(
                            hintText: "Cole a URL de uma imagem aqui",
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link, color: Colors.indigo),
                        onPressed: () {
                          if (_photoUrlController.text.isNotEmpty) {
                            setState(() {
                              photos.add(_photoUrlController.text);
                              _photoUrlController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Opção 2: Câmera/Galeria
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceSheet,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text("Tirar Foto ou Escolher da Galeria"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Listagem de Imagens (URLs + Locais)
                  if (photos.isNotEmpty || _localImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Renderizar URLs
                          ...photos.map((url) => _imageThumbnail(url: url)),
                          // Renderizar Arquivos Locais
                          ..._localImages.map(
                            (file) => _imageThumbnail(file: file),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text("Tornar pública?"),
                    subtitle: const Text(
                      "Outros usuários verão na aba Comunidade.",
                    ),
                    value: isPublic,
                    activeColor: Colors.indigo,
                    onChanged: (v) => setState(() => isPublic = v),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isUploading ? null : _saveRecommendation,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "PUBLICAR RECOMENDAÇÃO",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text("Enviando recomendação..."),
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

  Widget _imageThumbnail({String? url, File? file}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url != null
                ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover)
                : Image.file(file!, width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (url != null) photos.remove(url);
                  if (file != null) _localImages.remove(file);
                });
              },
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
