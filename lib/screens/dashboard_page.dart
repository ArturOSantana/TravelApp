import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/trip_controller.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'trips_page.dart';
import 'insights_page.dart';
import 'services_library_page.dart';
import 'profile_page.dart';
import 'flight_search_page.dart';
import 'hotel_search_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthController _authController = AuthController();
  final TripController _tripController = TripController();
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

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    "Notificações",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Fechar notificações",
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _tripController.getNotifications(),
                builder: (context, snapshot) {
                  // Estado de erro
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          const Text("Erro ao carregar notificações"),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Estado de carregamento
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Sem dados ainda
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text("Nenhuma notificação por enquanto."),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data!;

                  // Lista vazia
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text("Nenhuma notificação por enquanto."),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];

                      // Definir ícone e cor baseado no tipo
                      IconData icon;
                      Color color;
                      String message;

                      switch (notif.type) {
                        case NotificationType.like:
                          icon = Icons.favorite;
                          color = Colors.red;
                          message = "${notif.senderName} curtiu seu post";
                          break;
                        case NotificationType.comment:
                          icon = Icons.comment;
                          color = Colors.blue;
                          message = "${notif.senderName} comentou no seu post";
                          break;
                        case NotificationType.safetyAlert:
                          icon = Icons.warning;
                          color = Colors.orange;
                          message = "🆘 ALERTA DE SEGURANÇA";
                          break;
                      }

                      return Semantics(
                        button: true,
                        label: "Notificação de ${notif.senderName}",
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: notif.isRead ? null : color.withOpacity(0.05),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Text(
                              message,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color:
                                    notif.type == NotificationType.safetyAlert
                                    ? Colors.orange[900]
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (notif.type ==
                                        NotificationType.safetyAlert &&
                                    notif.commentText != null)
                                  Text(
                                    notif.commentText!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Text(
                                    notif.postName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(notif.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _tripController.markNotificationAsRead(notif.id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text("Travel Planner")),
        actions: [
          // Ícone do SINO (W3C: Nome descritivo e contador acessível)
          StreamBuilder<List<AppNotification>>(
            stream: _tripController.getNotifications(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              // Só conta se tiver dados válidos
              if (snapshot.hasData && snapshot.data != null) {
                unreadCount = snapshot.data!.where((n) => !n.isRead).length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => _showNotifications(context),
                    tooltip: unreadCount > 0
                        ? "Você tem $unreadCount novas notificações"
                        : "Sem novas notificações",
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Meu Perfil",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) => _loadUser()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Sair da conta",
            onPressed: () async => await _authController.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                "Olá, ${_user?.name.split(' ')[0] ?? 'Viajante'}!",
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildMainCard(
              context,
              "Minhas Viagens",
              "Gerencie seus roteiros",
              Icons.explore_rounded,
              Colors.deepPurple,
              "Clique para ver suas viagens planejadas e ativas",
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TripsPage()),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildSmallMainCard(
                    context,
                    "Voos",
                    Icons.flight_takeoff_rounded,
                    Colors.blue[800]!,
                    "Buscar passagens aéreas",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlightSearchPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSmallMainCard(
                    context,
                    "Hotéis",
                    Icons.hotel_rounded,
                    Colors.indigo[900]!,
                    "Buscar reservas de hospedagem",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HotelSearchPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            Semantics(
              header: true,
              child: Text(
                "Ferramentas",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: screenWidth > 600 ? 3 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildGridItem(
                  context,
                  "Insights",
                  Icons.analytics_rounded,
                  Colors.deepOrange,
                  "Ver estatísticas financeiras",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsightsPage(),
                    ),
                  ),
                ),
                _buildGridItem(
                  context,
                  "Comunidade",
                  Icons.people_alt_rounded,
                  Colors.indigo,
                  "Ver recomendações de outros usuários",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServicesLibraryPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    String semanticLabel,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sub,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallMainCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String semanticLabel,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String semanticLabel,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
