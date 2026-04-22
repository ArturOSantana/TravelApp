import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para o MethodChannel
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/safety_checkin.dart';
import '../models/user_model.dart';
import '../models/trip.dart';
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
  
  // Nosso canal de comunicação com o Android nativo
  static const platform = MethodChannel('com.example.travel_app/sms');
  
  bool _isLoading = false;
  UserModel? _user;
  Trip? _trip;

  Timer? _safetyTimer;
  int _secondsRemaining = 0;
  bool _timerActive = false;

  Position? _safeDestination;
  String? _safeDestinationName;
  StreamSubscription<Position>? _positionStream;
  bool _hasExitedSafeZone = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authController.getUserData();
      final trip = await _controller.getTripById(widget.tripId);
      if (mounted) {
        setState(() {
          _user = user;
          _trip = trip;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ative o GPS do seu aparelho.")));
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<void> _setDestination() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      String addr = await _getAddressFromCoords(position.latitude, position.longitude);
      setState(() {
        _safeDestination = position;
        _safeDestinationName = addr;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Destino definido: $addr"), backgroundColor: Colors.blue));
      }
    } catch (e) {
      debugPrint("Erro ao definir destino: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startSafetyTimer(int minutes) {
    _safetyTimer?.cancel();
    _positionStream?.cancel();

    setState(() {
      _secondsRemaining = minutes * 60;
      _timerActive = true;
      _hasExitedSafeZone = false;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5
      )
    ).listen((Position position) {
      if (_safeDestination != null && _timerActive) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          _safeDestination!.latitude, _safeDestination!.longitude
        );

        if (distance < 50) {
          _handleArrival();
        } 
        
        if (distance > 300 && !_hasExitedSafeZone) {
          _hasExitedSafeZone = true;
          _notifyExitSafeZone(position);
        }
      }
    });

    _safetyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopMonitoring();
          _triggerFullSOS(); 
        }
      });
    });
  }

  void _handleArrival() {
    _stopMonitoring();
    _controller.performSafetyCheckIn(widget.tripId, "Chegada Automática: ${_safeDestinationName ?? 'Destino'}", false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você chegou em segurança!"), backgroundColor: Colors.green));
    }
  }

  void _notifyExitSafeZone(Position pos) async {
    if (_trip != null && _trip!.members.length > 1) {
      String addr = await _getAddressFromCoords(pos.latitude, pos.longitude);
      await _controller.performSafetyCheckIn(widget.tripId, "⚠️ DESVIO DE ROTA: Estou em $addr", false);
    }
  }

  void _stopMonitoring() {
    _safetyTimer?.cancel();
    _positionStream?.cancel();
    setState(() {
      _timerActive = false;
      _secondsRemaining = 0;
    });
  }

  // --- LÓGICA DE ENVIO DE SMS REAL VIA MÉTODO NATIVO ---
  Future<void> _sendRealSMS(String phone, String message) async {
    try {
      final String result = await platform.invokeMethod('sendSms', {
        "phone": phone,
        "message": message,
      });
      debugPrint("SMS STATUS: $result");
    } on PlatformException catch (e) {
      debugPrint("FALHA AO ENVIAR SMS NATIVO: '${e.message}'. Tentando WhatsApp...");
      final whatsappUrl = Uri.parse("whatsapp://send?phone=55$phone&text=${Uri.encodeComponent(message)}");
      if (await canLaunchUrl(whatsappUrl)) await launchUrl(whatsappUrl);
    }
  }

  Future<void> _triggerFullSOS() async {
    if (_user == null) return;

    try {
      debugPrint("[SEGURANÇA] Iniciando captura de localização precisa...");
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (e) {
        pos = await Geolocator.getLastKnownPosition();
      }

      String loc = pos != null 
          ? await _getAddressFromCoords(pos.latitude, pos.longitude)
          : "Localização não obtida (verifique o sinal)";
      
      debugPrint("[SEGURANÇA] Localização obtida: $loc");

      bool inGroup = (_trip?.members.length ?? 0) > 1;
      final message = "SOS TRAVEL APP: ${_user!.name} precisa de ajuda urgente. Localizacao: $loc";
      final cleanPhone = _user!.emergencyPhone.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. FIREBASE (GRUPO)
      if (inGroup) {
        debugPrint("[SEGURANÇA] Enviando alerta para o grupo via Firebase...");
        await _controller.performSafetyCheckIn(widget.tripId, loc, true);
      }

      // 2. SMS REAL (NOSSO MÉTODO NOVO)
      if (cleanPhone.isNotEmpty) {
        debugPrint("[SEGURANÇA] Enviando SMS Real para $cleanPhone...");
        await _sendRealSMS(cleanPhone, message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ALERTA CRÍTICO DISPARADO!"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Erro geral no SOS: $e");
    }
  }

  Future<String> _getAddressFromCoords(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=pt-BR'),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      ).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parts = data['display_name'].toString().split(',');
        return parts.length > 2 ? "${parts[0]}, ${parts[1]}, ${parts[2]}" : parts[0];
      }
    } catch (e) {}
    return "Local: $lat, $lon";
  }

  void _showSetupContactDialog() {
    final nameController = TextEditingController(text: _user?.emergencyContact);
    final phoneController = TextEditingController(text: _user?.emergencyPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contato de Emergência"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Telefone (com DDD)"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (_user != null) {
                final updated = _user!.copyWith(
                  emergencyContact: nameController.text,
                  emergencyPhone: phoneController.text,
                );
                await _authController.updateUserProfile(updated);
                _loadInitialData();
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Segurança Ativa", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmergencyContactCard(),
                const SizedBox(height: 20),
                _buildDestinationCard(),
                const SizedBox(height: 20),
                if (_timerActive) _buildActiveTimerUI() else _buildStartMonitoringUI(),
                const SizedBox(height: 30),
                const Text("AÇÕES RÁPIDAS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                _buildPanicButton(),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("HISTÓRICO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13, letterSpacing: 0.8)),
                    Icon(Icons.history, size: 16, color: Colors.blueGrey.withOpacity(0.6)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTimelineHistory(),
              ],
            ),
          ),
    );
  }

  Widget _buildEmergencyContactCard() {
    bool hasContact = _user?.emergencyPhone.isNotEmpty ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hasContact ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(hasContact ? Icons.contact_phone : Icons.person_add, color: hasContact ? Colors.green : Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Contato de Emergência", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text(
                  hasContact ? "${_user!.emergencyContact} (${_user!.emergencyPhone})" : "Não configurado",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('edit_contact_btn'),
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
            onPressed: _showSetupContactDialog,
          )
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _safeDestinationName != null ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _safeDestinationName != null ? Colors.blue.shade100 : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: _safeDestinationName != null ? Colors.blue : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Destino de Segurança", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    Text(
                      _safeDestinationName ?? "Marque seu local de chegada",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _safeDestinationName != null ? Colors.blue.shade900 : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_safeDestinationName == null)
                TextButton.icon(
                  key: const Key('set_destination_btn'),
                  onPressed: _setDestination,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                  label: const Text("Marcar", style: TextStyle(fontSize: 13)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.blue),
                  onPressed: () => setState(() => _safeDestinationName = null),
                )
            ],
          ),
          if (_safeDestinationName != null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 36),
              child: Text("Parada automática ao chegar aqui.", style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
            )
        ],
      ),
    );
  }

  Widget _buildStartMonitoringUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Duração do Trajeto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Defina quanto tempo você levará.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _timeChip(15, "15m", const Key('time_15m')),
              const SizedBox(width: 8),
              _timeChip(30, "30m", const Key('time_30m')),
              const SizedBox(width: 8),
              _timeChip(60, "1h", const Key('time_60m')),
              const SizedBox(width: 8),
              _timeChip(120, "2h", const Key('time_120m')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimerUI() {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text("MONITORAMENTO ATIVO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}", 
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.orange, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _stopMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("ESTOU SEGURO / CHEGUEI", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('panic_btn'),
        onTap: _triggerFullSOS,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("BOTÃO DE PÂNICO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    Text("Alertar grupo e contatos agora", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHistory() {
    return StreamBuilder<List<SafetyCheckIn>>(
      stream: _controller.getSafetyHistory(widget.tripId),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const Center(child: Text("Sem registros recentes.", style: TextStyle(color: Colors.grey, fontSize: 13)));
        
        return Column(
          children: list.take(5).map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(color: item.isPanic ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.isPanic ? "ALERTA DE SEGURANÇA" : "Check-in Seguro", 
                             style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: item.isPanic ? Colors.red : Colors.black87)),
                        Text(item.locationName, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(DateFormat('HH:mm').format(item.timestamp), style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _timeChip(int min, String label, Key key) {
    return Expanded(
      child: ActionChip(
        key: key,
        label: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        onPressed: () => _startSafetyTimer(min),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
