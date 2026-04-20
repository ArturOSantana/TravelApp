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

  void _triggerFullSOS() async {
    if (_user == null || _user!.emergencyPhone.isEmpty) {
      _showSetupDialog();
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      double mockLat = -23.5505; 
      double mockLon = -46.6333;
      String locationName = await _getAddressFromCoords(mockLat, mockLon);
      
      await _controller.performSafetyCheckIn(widget.tripId, locationName, true);

      final message = "🆘 EMERGÊNCIA! Sou o(a) ${_user!.name}. Estou em perigo. Localização: $locationName. POR FAVOR, AJUDA!";
      final cleanPhone = _user!.emergencyPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final formattedPhone = "55$cleanPhone";

      final smsUri = Uri.parse("sms:$formattedPhone?body=${Uri.encodeComponent(message)}");
      final whatsappUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao disparar SOS: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSafetyAction(bool isPanic) async {
    if (isPanic) {
      _triggerFullSOS();
    } else {
      setState(() => _isLoading = true);
      String addr = await _getAddressFromCoords(-23.55, -46.63);
      await _controller.performSafetyCheckIn(widget.tripId, addr, false);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check-in de segurança realizado!"), backgroundColor: Colors.green));
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
            const Text("O app enviará alertas para este número em emergências."),
            const SizedBox(height: 15),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome do Contato", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Número com DDD", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (_user != null) {
                final updatedUser = _user!.copyWith(emergencyContact: nameController.text, emergencyPhone: phoneController.text);
                await _authController.updateUserProfile(updatedUser);
                _loadUserData();
              }
              Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Semantics(header: true, child: const Text("Segurança e SOS", style: TextStyle(fontWeight: FontWeight.bold))),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          Semantics(label: "Configurar contato de emergência", child: IconButton(icon: const Icon(Icons.settings), onPressed: _showSetupDialog))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Semantics(label: "Ícone de escudo de segurança", child: const Icon(Icons.security, size: 80, color: Colors.redAccent)),
                const SizedBox(height: 20),
                if (_user != null && _user!.emergencyContact.isNotEmpty)
                  Semantics(
                    label: "Status: SOS configurado para o contato ${_user!.emergencyContact}",
                    child: Text("SOS configurado para: ${_user!.emergencyContact}", 
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                const SizedBox(height: 15),
                const Text("Em caso de perigo, use os botões abaixo para notificar seus contatos.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 40),

                _buildSafetyButton(
                  "ESTOU SEGURO", 
                  "Fazer check-in de localização normal", 
                  Icons.check_circle_rounded, 
                  Colors.green,
                  "Clique para avisar que você está seguro no endereço atual",
                  () => _handleSafetyAction(false)
                ),

                const SizedBox(height: 20),

                _buildSafetyButton(
                  "BOTÃO DE PÂNICO", 
                  "ENVIAR ALERTA SOS IMEDIATO", 
                  Icons.warning_rounded, 
                  Colors.red,
                  "BOTÃO CRÍTICO: Enviar pedido de socorro via SMS e WhatsApp para seu contato de emergência",
                  () => _handleSafetyAction(true)
                ),

                const SizedBox(height: 40),
                const Divider(),
                Semantics(header: true, child: const Text("Histórico de Atividade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(height: 15),

                StreamBuilder<List<SafetyCheckIn>>(
                  stream: _controller.getSafetyHistory(widget.tripId),
                  builder: (context, snapshot) {
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) return const Text("Sem registros recentes.", style: TextStyle(color: Colors.grey));
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Semantics(
                          label: "Registro: ${item.isPanic ? 'ALERTA SOS' : 'Check-in seguro'} em ${DateFormat('HH:mm').format(item.timestamp)}. Local: ${item.locationName}",
                          child: ListTile(
                            leading: Icon(item.isPanic ? Icons.warning : Icons.check_circle, color: item.isPanic ? Colors.red : Colors.green),
                            title: Text(item.isPanic ? "SOS ENVIADO" : "Tudo Seguro"),
                            subtitle: Text("${DateFormat('dd/MM HH:mm').format(item.timestamp)}\n${item.locationName}", style: const TextStyle(fontSize: 10)),
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
    );
  }

  Widget _buildSafetyButton(String title, String sub, IconData icon, Color color, String semanticLabel, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
