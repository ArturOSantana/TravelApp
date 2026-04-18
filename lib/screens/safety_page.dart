import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/safety_checkin.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';

class SafetyPage extends StatefulWidget {
  final String tripId;
  const SafetyPage({super.key, required this.tripId});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final TripController _controller = TripController();
  final AuthController _authController = AuthController();
  
  bool _isLoading = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = await _authController.getUserData();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<String> _getAddressFromCoords(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=pt-BR'),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Localização Desconhecida";
      }
    } catch (e) {
      debugPrint("Erro reverse geocoding: $e");
    }
    return "Lat: $lat, Lon: $lon";
  }

  // Função mestre de SOS: Dispara SMS e WhatsApp
  void _triggerFullSOS() async {
    if (_user == null || _user!.emergencyPhone.isEmpty) {
      _showSetupDialog();
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // TODO: Usar geolocalizador real do dispositivo aqui
      // Por enquanto simulando coordenadas para o OSM Geocoding
      double mockLat = -23.5505; 
      double mockLon = -46.6333;

      String locationName = await _getAddressFromCoords(mockLat, mockLon);
      
      // 1. Registra no Firebase para o histórico
      await _controller.performSafetyCheckIn(widget.tripId, locationName, true);

      final message = "🆘 EMERGÊNCIA! Sou o(a) ${_user!.name}. Estou em perigo. Localização: $locationName. POR FAVOR, AJUDA!";
      
      final cleanPhone = _user!.emergencyPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final formattedPhone = "55$cleanPhone";

      final smsUri = Uri.parse("sms:$formattedPhone?body=${Uri.encodeComponent(message)}");
      final whatsappUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _showWhatsAppRedirect(whatsappUrl);
        });
      } else if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao disparar SOS: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWhatsAppRedirect(Uri url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("REFORÇAR SOS")],
        ),
        content: const Text("SMS enviado! Deseja enviar também pelo WhatsApp para garantir o recebimento?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Não")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              if (await canLaunchUrl(url)) await launchUrl(url);
            }, 
            child: const Text("Enviar WhatsApp")
          ),
        ],
      ),
    );
  }

  void _handleSafetyAction(bool isPanic) async {
    if (isPanic) {
      _triggerFullSOS();
    } else {
      setState(() => _isLoading = true);
      // Simulação de endereço para o check-in normal
      String addr = await _getAddressFromCoords(-23.55, -46.63);
      await _controller.performSafetyCheckIn(widget.tripId, addr, false);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-in de segurança realizado!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showSetupDialog() {
    final nameController = TextEditingController(text: _user?.emergencyContact);
    final phoneController = TextEditingController(text: _user?.emergencyPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Configurar Contato SOS"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("O app usará este número para enviar SMS e WhatsApp de emergência."),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome do Contato", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Número com DDD", 
                hintText: "11999999999", 
                border: OutlineInputBorder(),
                helperText: "Apenas números, sem o +55"
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (_user != null) {
                final updatedUser = _user!.copyWith(
                  emergencyContact: nameController.text,
                  emergencyPhone: phoneController.text,
                );
                await _authController.updateUserProfile(updatedUser);
                _loadUserData();
              }
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text("Salvar")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Segurança e SOS"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSetupDialog)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Icon(Icons.security, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                if (_user != null && _user!.emergencyContact.isNotEmpty)
                  Text("SOS configurado para: ${_user!.emergencyContact}", 
                       style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 10),
                const Text(
                  "Em caso de perigo, o botão abaixo notificará seu contato por SMS e WhatsApp com seu endereço atual.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                _buildSafetyButton(
                  "ESTOU SEGURO", 
                  "Registra check-in com endereço real", 
                  Icons.check_circle, 
                  Colors.green,
                  () => _handleSafetyAction(false)
                ),

                const SizedBox(height: 20),

                _buildSafetyButton(
                  "BOTÃO DE PÂNICO", 
                  "ENVIAR SOS COM ENDEREÇO VIA OSM", 
                  Icons.warning, 
                  Colors.red,
                  () => _handleSafetyAction(true)
                ),

                const SizedBox(height: 30),
                const Divider(),
                const Text("Histórico de Registros", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<List<SafetyCheckIn>>(
                    stream: _controller.getSafetyHistory(widget.tripId),
                    builder: (context, snapshot) {
                      final history = snapshot.data ?? [];
                      if (history.isEmpty) return const Center(child: Text("Nenhum registro."));
                      
                      return ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            leading: Icon(
                              item.isPanic ? Icons.warning : Icons.check_circle,
                              color: item.isPanic ? Colors.red : Colors.green,
                            ),
                            title: Text(item.isPanic ? "ALERTA SOS ENVIADO" : "Check-in de segurança"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('dd/MM HH:mm').format(item.timestamp)),
                                Text(item.locationName, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildSafetyButton(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
