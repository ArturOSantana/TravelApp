import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'trips_page.dart';
import 'insights_page.dart';
import 'services_library_page.dart';
import 'profile_page.dart';
import 'flight_search_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthController _authController = AuthController();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authController.getUserData();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) => _loadUser()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _authController.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Olá, ${_user?.name.split(' ')[0]}!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            _buildMainCard(
              context,
              "Minhas Viagens",
              "Gerencie seus roteiros e gastos",
              Icons.explore_rounded,
              Colors.deepPurple,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsPage())),
            ),
            
            const SizedBox(height: 15),

            _buildMainCard(
              context,
              "Busca de Vôos",
              "Encontre as melhores passagens",
              Icons.flight_takeoff_rounded,
              Colors.blue[800]!,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightSearchPage())),
            ),
            
            const SizedBox(height: 25),
            const Text("Ferramentas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildGridItem(
                  context,
                  "Insights",
                  Icons.analytics_rounded,
                  Colors.deepOrange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InsightsPage())),
                ),
                _buildGridItem(
                  context,
                  "Biblioteca",
                  Icons.local_library_rounded,
                  Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesLibraryPage())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(sub, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
