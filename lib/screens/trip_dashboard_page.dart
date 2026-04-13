import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/weather_service.dart';
import 'itinerary_page.dart';
import 'expenses_page.dart';
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
  final _authController = AuthController();
  Map<String, dynamic>? _weather;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final city = widget.trip.destination.split(',')[0].trim();
    final data = await WeatherService.getWeather(city);
    if (mounted) {
      setState(() {
        _weather = data;
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TripController();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final bool isAdm = widget.trip.ownerId.isNotEmpty 
        ? currentUid == widget.trip.ownerId 
        : (widget.trip.members.isNotEmpty && widget.trip.members.first == currentUid);

    final bool canFinish = widget.trip.status == 'active';

    // Usamos StreamBuilder para reagir INSTANTANEAMENTE às mudanças de Premium
    return StreamBuilder<UserModel?>(
      stream: _authController.userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final bool isPremium = user?.isPremium ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.trip.destination),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.group, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupMembersPage(trip: widget.trip))),
                tooltip: "Ver Membros",
              ),
              if (isAdm && widget.trip.status != 'completed')
                _buildFinishButton(canFinish, controller),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CLIMA: Agora reage na hora se o usuário virar Premium
                if (isPremium)
                  _isLoadingWeather 
                    ? _buildWeatherSkeleton() 
                    : (_weather != null ? _buildWeatherCard() : const SizedBox.shrink())
                else
                  _buildPremiumAdCard(),
                
                const SizedBox(height: 15),

                _buildTripInfoCard(),

                const SizedBox(height: 30),
                const Text("Gerenciamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                _buildOptionCard(
                  context, 
                  Icons.calendar_month, 
                  "Roteiro Inteligente", 
                  "Organize atividades e vote em grupo",
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryPage(tripId: widget.trip.id)))
                ),
                
                _buildOptionCard(
                  context, 
                  Icons.account_balance_wallet, 
                  "Controle Financeiro", 
                  isPremium ? "Gastos, divisão e câmbio real" : "Acesso limitado (Seja Premium)",
                  () {
                    if (isPremium) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ExpensesPage(tripId: widget.trip.id)));
                    } else {
                      _showPremiumModal();
                    }
                  },
                  isLocked: !isPremium,
                ),

                _buildOptionCard(
                  context, 
                  Icons.auto_stories, 
                  "Álbum de Viagem",
                  "Registre memórias e sentimentos",
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => JournalPage(tripId: widget.trip.id)))
                ),
                
                _buildOptionCard(
                  context, 
                  Icons.gpp_good, 
                  "Segurança e SOS", 
                  isPremium ? "Compartilhamento de localização real" : "SOS Básico (Seja Premium)",
                  () {
                    if (isPremium) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPage(tripId: widget.trip.id)));
                    } else {
                      _showPremiumModal();
                    }
                  },
                  isLocked: !isPremium,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildFinishButton(bool canFinish, TripController controller) {
    return TextButton.icon(
      onPressed: canFinish 
        ? () => _showFinishDialog(context, controller)
        : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("A viagem precisa estar 'Em andamento' para ser concluída."), backgroundColor: Colors.orange),
            );
          },
      icon: Icon(Icons.check_circle, color: canFinish ? Colors.white : Colors.white54),
      label: Text("Concluir", style: TextStyle(color: canFinish ? Colors.white : Colors.white54)),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CLIMA PREMIUM", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("${_weather!['temp']}°C", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text(_weather!['desc'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          Text(_weather!['icon'], style: const TextStyle(fontSize: 50)),
        ],
      ),
    );
  }

  Widget _buildWeatherSkeleton() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildPremiumAdCard() {
    return InkWell(
      onTap: _showPremiumModal,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Expanded(child: Text("Previsão do Tempo e Câmbio estão bloqueados. Seja Premium!", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: widget.trip.status == 'completed' ? Colors.grey : Colors.deepPurple,
            child: Icon(widget.trip.status == 'completed' ? Icons.archive : Icons.flight_takeoff, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.trip.destination, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Status: ${widget.trip.status == 'active' ? 'Em andamento' : 'Planejada'}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 60, color: Colors.amber),
            const SizedBox(height: 15),
            const Text("Travel App Premium", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Acesse câmbio em tempo real, clima detalhado e segurança avançada.", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () async {
                  final user = await _authController.getUserData();
                  if (user != null) {
                    await _authController.updateUserProfile(user.copyWith(isPremium: true));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agora você é PREMIUM! ⭐")));
                    }
                  }
                },
                child: const Text("ASSINAR AGORA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showFinishDialog(BuildContext context, TripController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Concluir Viagem?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await controller.updateTripStatus(widget.trip.id, 'completed');
              if (mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            child: const Text("Concluir"),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isLocked = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: isLocked ? Colors.grey[200] : Colors.deepPurple.withOpacity(0.1),
          child: Icon(icon, color: isLocked ? Colors.grey : Colors.deepPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isLocked ? const Icon(Icons.lock, size: 16, color: Colors.grey) : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
