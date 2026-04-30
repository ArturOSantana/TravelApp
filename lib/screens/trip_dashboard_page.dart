import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/openweathermap_service.dart';
import 'itinerary_page.dart';
import 'expenses_page.dart';
import 'packing_checklist_page.dart';
import 'journal_page.dart';
import 'safety_page.dart';
import 'group_members_page.dart';

class TripDashboardPage extends StatefulWidget {
  final Trip trip;
  const TripDashboardPage({super.key, required this.trip});

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage> {
  final TripController _controller = TripController();
  List<UserModel> _members = [];
  bool _isLoadingMembers = true;
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadWeather();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _controller.getTripMembers(widget.trip.members);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final city = widget.trip.destination.split(',')[0].trim();
      final weather = await OpenWeatherMapService.getCurrentWeather(city);
      if (mounted && weather != null) {
        setState(() {
          _weatherData = {
            'temp': weather['temp'],
            'desc': weather['description'] ?? 'Sem descrição',
            'icon_code': weather['icon'] ?? '01d',
          };
          _isLoadingWeather = false;
        });
      } else if (mounted) {
        setState(() {
          _weatherData = null;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar clima: $e');
      if (mounted) {
        setState(() {
          _weatherData = null;
          _isLoadingWeather = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return Icons.wb_sunny; // Céu limpo
      case '02d':
      case '02n':
        return Icons.wb_cloudy; // Poucas nuvens
      case '03d':
      case '03n':
        return Icons.cloud; // Nuvens dispersas
      case '04d':
      case '04n':
        return Icons.cloud_queue; // Nublado
      case '09d':
      case '09n':
        return Icons.grain; // Chuva
      case '10d':
      case '10n':
        return Icons.beach_access; // Chuva leve
      case '11d':
      case '11n':
        return Icons.flash_on; // Trovoada
      case '13d':
      case '13n':
        return Icons.ac_unit; // Neve
      case '50d':
      case '50n':
        return Icons.blur_on; // Névoa
      default:
        return Icons.wb_sunny;
    }
  }

  void _showFinalizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Finalizar Viagem?"),
        content: const Text(
            "Isso moverá a viagem para o seu histórico de viagens concluídas."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await _controller.updateTripStatus(widget.trip.id, 'completed');
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Finalizar Agora"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apagar Viagem?"),
        content:
            const Text("Tem certeza que deseja excluir este planejamento?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Manter")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _controller.deleteTrip(widget.trip.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Sim, Apagar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlanned = widget.trip.status == 'planned';
    final bool isActive = widget.trip.status == 'active';
    final bool isCompleted = widget.trip.status == 'completed';

    // URL estável para imagem de destino usando Unsplash Source
    final String cityImageUrl =
        "https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=1200&auto=format&fit=crop";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Semantics(
                label: "Botão voltar",
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Base: Gradiente de segurança (W3C Acessibilidade)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                      ),
                    ),
                  ),
                  // Imagem Real (Carregamento com Fade)
                  Image.network(
                    "https://source.unsplash.com/featured/1200x800?${Uri.encodeComponent(widget.trip.destination)}",
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => const SizedBox(),
                  ),
                  // Gradientes de Contraste para o Texto (WCAG)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.2, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Info da Viagem (Visual Premium + Semântica W3C)
                  Positioned(
                    bottom: 25,
                    left: 20,
                    right: 20,
                    child: Semantics(
                      header: true,
                      label:
                          "Cabeçalho da viagem para ${widget.trip.destination}",
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.trip.destination,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.trip.objective.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.calendar_today_outlined,
                                        color: Colors.white70, size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.trip.startDate != null
                                          ? DateFormat('MMM yyyy')
                                              .format(widget.trip.startDate!)
                                          : "A definir",
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isPlanned)
                _buildActionCircle(Icons.delete_outline, Colors.redAccent,
                    "Apagar planejamento", _showDeleteDialog)
              else if (isActive)
                _buildActionCircle(
                    Icons.check_circle_outline,
                    Colors.greenAccent,
                    "Finalizar viagem",
                    _showFinalizeDialog),
              _buildActionCircle(
                  Icons.group_outlined, Colors.white, "Ver membros do grupo",
                  () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            GroupMembersPage(trip: widget.trip)));
              }),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      "ESTADO ATUAL",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeatherCard(),
                  const SizedBox(height: 20),
                  _buildStatusSection(isActive, isCompleted),
                  const SizedBox(height: 40),
                  Semantics(
                    header: true,
                    child: Text(
                      "GESTÃO DA VIAGEM",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _buildMenuCard(context, "Roteiro", Icons.explore_rounded,
                          Colors.blue, "Planejar atividades"),
                      _buildMenuCard(
                          context,
                          "Gastos",
                          Icons.account_balance_wallet_rounded,
                          Colors.green,
                          "Controle financeiro"),
                      _buildMenuCard(context, "Checklist", Icons.rule_rounded,
                          Colors.orange, "Organizar bagagem"),
                      _buildMenuCard(
                          context,
                          "Registros",
                          Icons.auto_awesome_motion_rounded,
                          Colors.pink,
                          "Fotos e memórias"),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSecurityAction(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(
      IconData icon, Color color, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(0.25),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather)
      return const LinearProgressIndicator(
          minHeight: 2, backgroundColor: Colors.transparent);
    if (_weatherData == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getWeatherIcon(_weatherData!['icon_code']),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_weatherData!['temp']}°C",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                _weatherData!['desc'].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.cloud_sync_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isActive, bool isCompleted) {
    String text = isCompleted
        ? "VIAGEM CONCLUÍDA"
        : (isActive ? "EM ANDAMENTO" : "PRÓXIMA VIAGEM");
    Color color = isCompleted
        ? Colors.grey
        : (isActive ? Colors.green : Colors.orangeAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 16),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color color, String sub) {
    return Semantics(
      button: true,
      label: "$title. $sub",
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (title == "Roteiro")
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ItineraryPage(tripId: widget.trip.id)));
              if (title == "Gastos")
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ExpensesPage(tripId: widget.trip.id)));
              if (title == "Checklist")
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PackingChecklistPage(tripId: widget.trip.id)));
              if (title == "Registros")
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            JournalPage(tripId: widget.trip.id)));
            },
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityAction(BuildContext context) {
    return Semantics(
      button: true,
      label: "Ação de segurança: Fazer check-in rápido de localização",
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Material(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SafetyPage(tripId: widget.trip.id))),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SEGURANÇA",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1)),
                      Text("Check-in de localização",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
