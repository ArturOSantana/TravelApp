import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ative o GPS do seu aparelho.")),
        );
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
      String addr = await _getAddressFromCoords(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _safeDestination = position;
        _safeDestinationName = addr;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Destino definido: $addr"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao definir destino: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildMapsUrl({
    required double latitude,
    required double longitude,
  }) {
    return "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
  }

  String _buildSafetyAlertMessage({
    required String location,
    double? latitude,
    double? longitude,
  }) {
    final mapLink = latitude != null && longitude != null
        ? _buildMapsUrl(latitude: latitude, longitude: longitude)
        : "Localização indisponível";

    return "🆘 SOS TRAVEL APP: ${_user?.name ?? 'Viajante'} precisa de ajuda urgente!\n"
        "Viagem: ${_trip?.destination ?? 'Viagem'}\n"
        "Localização: $location\n"
        "Mapa: $mapLink\n"
        "Horário: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}";
  }

  Future<void> _openEmergencyEmail({
    required String message,
  }) async {
    final recipients = <String>{};

    if (_user?.email.trim().isNotEmpty ?? false) {
      recipients.add(_user!.email.trim());
    }

    final mailto = Uri(
      scheme: 'mailto',
      path: recipients.join(','),
      queryParameters: {
        'subject': 'ALERTA SOS - ${_trip?.destination ?? 'Travel App'}',
        'body': message,
      },
    );

    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
    }
  }

  Future<void> _openLocationShareOptions({
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final message = _buildSafetyAlertMessage(
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
    final mapUrl = latitude != null && longitude != null
        ? Uri.parse(_buildMapsUrl(latitude: latitude, longitude: longitude))
        : null;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 12,
              children: [
                ListTile(
                  leading: Icon(Icons.mail_outline, color: colorScheme.primary),
                  title: const Text("Abrir e-mail de emergência"),
                  subtitle: const Text(
                      "Preenche assunto e mensagem com sua localização"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _openEmergencyEmail(message: message);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.map_outlined, color: colorScheme.primary),
                  title: const Text("Abrir localização no mapa"),
                  subtitle: const Text(
                      "Permite mostrar sua posição para outra pessoa"),
                  onTap: () async {
                    Navigator.pop(context);
                    if (mapUrl != null && await canLaunchUrl(mapUrl)) {
                      await launchUrl(mapUrl,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_safeDestination != null && _timerActive) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _safeDestination!.latitude,
          _safeDestination!.longitude,
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

  void _handleArrival() async {
    _stopMonitoring();
    if (_safeDestination != null) {
      await _controller.performSafetyCheckIn(
        widget.tripId,
        "Chegada Automática: ${_safeDestinationName ?? 'Destino'}",
        false,
        latitude: _safeDestination!.latitude,
        longitude: _safeDestination!.longitude,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Você chegou em segurança!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _notifyExitSafeZone(Position pos) async {
    if (_trip != null && _trip!.members.length > 1) {
      String addr = await _getAddressFromCoords(pos.latitude, pos.longitude);
      await _controller.performSafetyCheckIn(
        widget.tripId,
        "⚠️ DESVIO DE ROTA: Estou em $addr",
        false,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Grupo notificado sobre desvio de rota"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
      debugPrint(
        "FALHA AO ENVIAR SMS NATIVO: '${e.message}'. Tentando WhatsApp...",
      );
      final whatsappUrl = Uri.parse(
        "whatsapp://send?phone=55$phone&text=${Uri.encodeComponent(message)}",
      );
      if (await canLaunchUrl(whatsappUrl)) await launchUrl(whatsappUrl);
    }
  }

  Future<void> _triggerFullSOS() async {
    if (_user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                "ALERTA SOS",
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
          content: const Text(
            "Você está prestes a enviar um alerta de emergência para:\n\n"
            "• Todos os membros do grupo\n"
            "• Seu contato de emergência\n\n"
            "Confirma que precisa de ajuda?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text("SIM, PRECISO DE AJUDA"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      debugPrint("[SEGURANÇA] Iniciando captura de localização precisa...");
      Position? pos;

      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (e) {
        debugPrint("[SEGURANÇA] Erro ao obter localização atual: $e");
        pos = await Geolocator.getLastKnownPosition();
      }

      final loc = pos != null
          ? await _getAddressFromCoords(pos.latitude, pos.longitude)
          : "Localização não obtida (verifique o sinal)";

      debugPrint("[SEGURANÇA] Localização obtida: $loc");

      final inGroup = (_trip?.members.length ?? 0) > 1;
      final message = _buildSafetyAlertMessage(
        location: loc,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      final cleanPhone =
          _user!.emergencyPhone.replaceAll(RegExp(r'[^0-9]'), '');

      await _controller.performSafetyCheckIn(
        widget.tripId,
        loc,
        true,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (cleanPhone.isNotEmpty) {
        debugPrint("[SEGURANÇA] Enviando SMS Real para $cleanPhone...");
        await _sendRealSMS(cleanPhone, message);
      } else {
        debugPrint("[SEGURANÇA] Nenhum telefone de emergência configurado");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "🆘 ALERTA ENVIADO!\n"
                    "${inGroup ? 'Grupo notificado no app' : 'Alerta salvo no app'}"
                    "${cleanPhone.isNotEmpty ? '\nSMS preparado/enviado ao contato' : ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "COMPARTILHAR",
              textColor: Colors.white,
              onPressed: () => _openLocationShareOptions(
                location: loc,
                latitude: pos?.latitude,
                longitude: pos?.longitude,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("[SEGURANÇA] Erro geral no SOS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erro ao enviar alerta. Tente novamente."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String> _getAddressFromCoords(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=pt-BR',
        ),
        headers: {'User-Agent': 'TravelPlannerApp/1.0'},
      ).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parts = data['display_name'].toString().split(',');
        return parts.length > 2
            ? "${parts[0]}, ${parts[1]}, ${parts[2]}"
            : parts[0];
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Telefone (com DDD)",
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
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
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Segurança Ativa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
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
                  _buildActiveAlertCard(),
                  const SizedBox(height: 20),
                  _buildDestinationCard(),
                  const SizedBox(height: 20),
                  if (_timerActive)
                    _buildActiveTimerUI()
                  else
                    _buildStartMonitoringUI(),
                  const SizedBox(height: 30),
                  Text(
                    "AÇÕES RÁPIDAS",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildPanicButton(),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "HISTÓRICO",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                      ),
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    bool hasContact = _user?.emergencyPhone.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hasContact
                ? colorScheme.tertiaryContainer
                : colorScheme.secondaryContainer,
            child: Icon(
              hasContact ? Icons.contact_phone : Icons.person_add,
              color: hasContact
                  ? colorScheme.onTertiaryContainer
                  : colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contato de Emergência",
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hasContact
                      ? "${_user!.emergencyContact} (${_user!.emergencyPhone})"
                      : "Não configurado",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('edit_contact_btn'),
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            onPressed: _showSetupContactDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _controller.watchActiveSafetyAlert(widget.tripId),
      builder: (context, snapshot) {
        final alert = snapshot.data;
        if (alert == null) {
          return const SizedBox.shrink();
        }

        final locationName =
            (alert['locationName'] ?? 'Localização não informada').toString();
        final userName = (alert['userName'] ?? 'Viajante').toString();
        final latitude = (alert['latitude'] as num?)?.toDouble();
        final longitude = (alert['longitude'] as num?)?.toDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.error.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sos, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ALERTA ATIVO DE SEGURANÇA",
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "$userName compartilhou uma localização de emergência.",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locationName,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openLocationShareOptions(
                      location: locationName,
                      latitude: latitude,
                      longitude: longitude,
                    ),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text("Ver/Compartilhar localização"),
                  ),
                  if ((_user?.emergencyPhone.trim().isNotEmpty ?? false))
                    FilledButton.icon(
                      onPressed: () async {
                        final message = _buildSafetyAlertMessage(
                          location: locationName,
                          latitude: latitude,
                          longitude: longitude,
                        );
                        final cleanPhone = _user!.emergencyPhone.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (cleanPhone.isNotEmpty) {
                          await _sendRealSMS(cleanPhone, message);
                        }
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text("Reenviar SMS"),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDestinationCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasDestination = _safeDestinationName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            hasDestination ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              hasDestination ? colorScheme.outlineVariant : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: hasDestination
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Destino de Segurança",
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _safeDestinationName ?? "Marque seu local de chegada",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasDestination
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!hasDestination)
                TextButton.icon(
                  key: const Key('set_destination_btn'),
                  onPressed: _setDestination,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                  label: const Text("Marcar", style: TextStyle(fontSize: 13)),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => setState(() => _safeDestinationName = null),
                ),
            ],
          ),
          if (hasDestination)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 36),
              child: Text(
                "Parada automática ao chegar aqui.",
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartMonitoringUI() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Duração do Trajeto",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            "Defina quanto tempo você levará.",
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondaryContainer, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, color: colorScheme.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                "MONITORAMENTO ATIVO",
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
            style: textTheme.displaySmall?.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _stopMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ESTOU SEGURO / CHEGUEI",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('panic_btn'),
        onTap: _triggerFullSOS,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: colorScheme.error.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.onError,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BOTÃO DE PÂNICO",
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                    Text(
                      "Alertar grupo e contatos agora",
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHistory() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<SafetyCheckIn>>(
      stream: _controller.getSafetyHistory(widget.tripId),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              "Sem registros recentes.",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          );
        }

        return Column(
          children: list.take(5).map((item) {
            final accentColor =
                item.isPanic ? colorScheme.error : colorScheme.tertiary;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isPanic
                              ? "ALERTA DE SEGURANÇA"
                              : "Check-in Seguro",
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.isPanic
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          item.locationName,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(item.timestamp),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _timeChip(int min, String label, Key key) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: ActionChip(
        key: key,
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        onPressed: () => _startSafetyTimer(min),
        backgroundColor: colorScheme.surface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
