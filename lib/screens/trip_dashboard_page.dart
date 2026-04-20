import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/weather_service.dart';
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
      final weather = await WeatherService.getWeather(city);
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.trip.status == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Semantics(
                header: true,
                child: Text(
                  widget.trip.destination,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    label: "Imagem de fundo da viagem para ${widget.trip.destination}",
                    child: Container(color: Colors.deepPurple[800]),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Semantics(
                label: "Gerenciar membros do grupo",
                child: IconButton(
                  icon: const Icon(Icons.group_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupMembersPage(trip: widget.trip)),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherCard(),
                  const SizedBox(height: 15),
                  _buildStatusCard(isActive),
                  const SizedBox(height: 25),
                  
                  Semantics(
                    header: true,
                    child: const Text("Explorar Viagem", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMenuCard(context, "Roteiro", Icons.map_outlined, Colors.blue, "Ver cronograma de atividades", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryPage(tripId: widget.trip.id)))),
                      _buildMenuCard(context, "Gastos", Icons.payments_outlined, Colors.green, "Gerenciar orçamento e despesas", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExpensesPage(tripId: widget.trip.id)))),
                      _buildMenuCard(context, "Checklist", Icons.checklist_rtl, Colors.orange, "Lista de bagagem e preparativos", () => Navigator.push(context, MaterialPageRoute(builder: (context) => PackingChecklistPage(tripId: widget.trip.id)))),
                      // ALTERADO DE "Diário" PARA "Registros"
                      _buildMenuCard(context, "Registros", Icons.auto_stories_outlined, Colors.pink, "Ver fotos e memórias registradas", () => Navigator.push(context, MaterialPageRoute(builder: (context) => JournalPage(tripId: widget.trip.id)))),
                    ],
                  ),

                  const SizedBox(height: 30),
                  
                  Semantics(
                    header: true,
                    child: const Text("Segurança", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  
                  _buildMenuCard(
                    context, 
                    "Check-in de Segurança", 
                    Icons.security_outlined, 
                    Colors.redAccent, 
                    "Avisar contatos de emergência sobre sua localização",
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPage(tripId: widget.trip.id))),
                    isFullWidth: true
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather) return Container(height: 80, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2));
    if (_weatherData == null) return const SizedBox.shrink();
    return Semantics(
      label: "Clima atual em ${widget.trip.destination}: ${_weatherData!['temp']} graus, ${_weatherData!['desc']}",
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue[100]!)),
        child: Row(
          children: [
            Text(_weatherData!['icon'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_weatherData!['temp']}°C", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(_weatherData!['desc'].toString().toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[800])),
              ],
            ),
            const Spacer(),
            TextButton.icon(onPressed: _loadWeather, icon: const Icon(Icons.refresh, size: 16), label: const Text("Atualizar", style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle), child: Icon(isActive ? Icons.play_arrow : Icons.calendar_month, color: isActive ? Colors.green : Colors.orange)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isActive ? "Viagem em Andamento" : "Viagem Planejada", style: const TextStyle(fontWeight: FontWeight.bold)), Text(widget.trip.startDate != null ? "Início: ${DateFormat('dd/MM/yyyy').format(widget.trip.startDate!)}" : "Data a definir", style: const TextStyle(color: Colors.black54, fontSize: 12))])),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, String semanticLabel, VoidCallback onTap, {bool isFullWidth = false}) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: isFullWidth ? double.infinity : null,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          ),
        ),
      ),
    );
  }
}
