import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  
  String name = '';
  String category = 'Restaurante';
  String location = '';
  double rating = 5.0;
  String comment = '';
  double averageCost = 0.0;
  bool isPublic = true;
  List<String> photos = [];
  final TextEditingController _photoController = TextEditingController();

  final List<String> categories = ['Hospedagem', 'Restaurante', 'Transporte', 'Passeio', 'Serviço'];

  void _saveRecommendation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final user = FirebaseAuth.instance.currentUser;
      final newService = ServiceModel(
        id: '', // Firestore gera o ID
        ownerId: user?.uid ?? '',
        userName: user?.displayName ?? 'Viajante',
        name: name,
        category: category,
        location: location,
        rating: rating,
        comment: comment,
        averageCost: averageCost,
        lastUsed: DateTime.now(),
        isPublic: isPublic,
        photos: photos,
      );

      await _controller.saveService(newService);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recomendação salva com sucesso!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Recomendação"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("O que você quer recomendar?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextFormField(
                decoration: const InputDecoration(labelText: "Nome do Local/Serviço", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Informe o nome" : null,
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: "Categoria", border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(labelText: "Localização (Cidade/País)", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Informe a localização" : null,
                onSaved: (value) => location = value!,
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  const Text("Sua Nota: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: rating,
                      min: 1, max: 5, divisions: 4,
                      label: rating.toString(),
                      onChanged: (v) => setState(() => rating = v),
                    ),
                  ),
                  Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              
              TextFormField(
                decoration: const InputDecoration(labelText: "Custo Médio (R\$)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onSaved: (value) => averageCost = double.tryParse(value!) ?? 0.0,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(labelText: "Sua Opinião / Dicas Importantes", border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Escreva um comentário" : null,
                onSaved: (value) => comment = value!,
              ),
              const SizedBox(height: 15),
              
              const Text("Fotos (Cole a URL da imagem)", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _photoController,
                      decoration: const InputDecoration(hintText: "http://..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Colors.deepPurple),
                    onPressed: () {
                      if (_photoController.text.isNotEmpty) {
                        setState(() {
                          photos.add(_photoController.text);
                          _photoController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (photos.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(photos[index], width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 15),
              SwitchListTile(
                title: const Text("Tornar pública para a comunidade?"),
                subtitle: const Text("Outros viajantes poderão ver sua dica."),
                value: isPublic,
                onChanged: (v) => setState(() => isPublic = v),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: _saveRecommendation,
                  child: const Text("PUBLICAR RECOMENDAÇÃO", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
