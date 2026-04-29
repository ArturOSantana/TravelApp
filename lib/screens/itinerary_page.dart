import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/external_apps_service.dart';
import 'create_activity_page.dart';
import 'activity_suggestions_page.dart';
import 'premium_upgrade_page.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TripController _controller = TripController();
  final AuthController _authController = AuthController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedCategory = 'Todos';
  String _selectedFilter = 'Todos';
  String _selectedStatus = 'Todas';
  Trip? _trip;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _loadUser();
  }

  Future<void> _loadTrip() async {
    final trip = await _controller.getTripById(widget.tripId);
    if (mounted) {
      setState(() => _trip = trip);
    }
  }

  Future<void> _loadUser() async {
    final user = await _authController.getUserData();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Recurso Premium'),
          ],
        ),
        content: const Text(
          'As sugestões inteligentes de atividades são exclusivas para usuários Premium.\n\n'
          'Upgrade agora e tenha acesso a:\n'
          '• Sugestões de atrações turísticas\n'
          '• Recomendações de restaurantes\n'
          '• Informações sobre entretenimento\n'
          '• Dados do clima e país\n'
          '• Conversão de moedas',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.star),
            label: const Text('Fazer Upgrade'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumUpgradePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text(
            "Roteiro da Viagem",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSuggestionsButton(),
          _buildCategoryFilter(),
          _buildStatusFilter(),
          if (_trip?.isGroup ?? false) _buildVoteFilter(),
          Expanded(child: _buildActivityList()),
        ],
      ),
      floatingActionButton: Semantics(
        label: "Adicionar nova atividade ao roteiro",
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateActivityPage(tripId: widget.tripId),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSuggestionsButton() {
    if (_trip == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Ver Sugestões de Atividades'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            // Verificar se é premium
            if (_currentUser?.isPremium != true) {
              _showPremiumDialog();
              return;
            }

            // Buscar coordenadas do destino
            try {
              final url = Uri.parse(
                'https://nominatim.openstreetmap.org/search?q=${_trip!.destination}&format=json&limit=1',
              );

              final response = await http.get(
                url,
                headers: {'User-Agent': 'TravelPlannerApp/1.0'},
              );

              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                if (data.isNotEmpty && mounted) {
                  final lat = double.tryParse(data[0]['lat']);
                  final lon = double.tryParse(data[0]['lon']);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivitySuggestionsPage(
                        tripId: widget.tripId,
                        destination: _trip!.destination,
                        lat: lat,
                        lon: lon,
                      ),
                    ),
                  );

                  // Se retornou dados, abrir tela de criar atividade com dados preenchidos
                  if (result != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateActivityPage(
                          tripId: widget.tripId,
                          suggestedName: result['name'],
                          suggestedLocation: result['location'],
                          suggestedLat: result['lat'],
                          suggestedLon: result['lon'],
                        ),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao buscar sugestões'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<String>>(
      stream: _controller.watchTripCategories(widget.tripId),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? ['Todos'];
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['Todas', 'Pendentes', 'Concluídas', 'Canceladas'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          const Text(
            'Status:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status, style: const TextStyle(fontSize: 12)),
                    selected: _selectedStatus == status,
                    onSelected: (val) =>
                        setState(() => _selectedStatus = status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteFilter() {
    final filters = ['Todos', 'Mais votados', 'Com comentários'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          const Text(
            'Filtrar:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter, style: const TextStyle(fontSize: 12)),
                    selected: _selectedFilter == filter,
                    onSelected: (val) =>
                        setState(() => _selectedFilter = filter),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<List<Activity>>(
      stream: _controller.getActivities(widget.tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allActivities = snapshot.data!;

        // Filtrar por categoria
        var activities = _selectedCategory == 'Todos'
            ? allActivities
            : allActivities
                .where((a) => a.category == _selectedCategory)
                .toList();

        // Filtrar por status
        if (_selectedStatus == 'Pendentes') {
          activities = activities
              .where((a) => a.status == ActivityStatus.pending)
              .toList();
        } else if (_selectedStatus == 'Concluídas') {
          activities = activities
              .where((a) => a.status == ActivityStatus.completed)
              .toList();
        } else if (_selectedStatus == 'Canceladas') {
          activities = activities
              .where((a) => a.status == ActivityStatus.cancelled)
              .toList();
        }

        // Filtrar por votação/comentários
        if (_selectedFilter == 'Mais votados') {
          activities = activities.where((a) {
            final upvotes = a.votes.values.where((v) => v == 1).length;
            final downvotes = a.votes.values.where((v) => v == -1).length;
            return upvotes > downvotes;
          }).toList();
          // Ordenar por mais votos
          activities.sort((a, b) {
            final aVotes = a.votes.values.where((v) => v == 1).length;
            final bVotes = b.votes.values.where((v) => v == 1).length;
            return bVotes.compareTo(aVotes);
          });
        } else if (_selectedFilter == 'Com comentários') {
          activities = activities.where((a) => a.opinions.isNotEmpty).toList();
          // Ordenar por mais comentários
          activities.sort(
            (a, b) => b.opinions.length.compareTo(a.opinions.length),
          );
        }

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text("Nenhuma atividade encontrada."),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity, index);
          },
        );
      },
    );
  }

  void _onReorder(List<Activity> activities, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;

    final item = activities.removeAt(oldIndex);
    activities.insert(newIndex, item);

    await _controller.reorderActivities(activities);
  }

  Widget _buildActivityCard(Activity activity, int index, {Key? key}) {
    final isGroupTrip = _trip?.isGroup ?? false;
    final upvotes = activity.votes.values.where((v) => v == 1).length;
    final downvotes = activity.votes.values.where((v) => v == -1).length;
    final userVote = activity.votes[_currentUid];

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Semantics(
        label:
            "Atividade: ${activity.title} às ${DateFormat('HH:mm').format(activity.time)} em ${activity.location}",
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                activity.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${DateFormat('dd/MM HH:mm').format(activity.time)} • ${activity.location}",
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(activity);
                  if (value == 'edit') _editActivity(activity);
                  if (value == 'opinion') _addOpinion(activity);
                  if (value == 'pending')
                    _updateStatus(activity, ActivityStatus.pending);
                  if (value == 'completed')
                    _updateStatus(activity, ActivityStatus.completed);
                  if (value == 'cancelled')
                    _updateStatus(activity, ActivityStatus.cancelled);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'opinion',
                    child: Row(
                      children: [
                        Icon(Icons.comment, size: 20),
                        SizedBox(width: 8),
                        Text('Adicionar opinião'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'pending',
                    child: Row(
                      children: [
                        Icon(Icons.pending, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Marcar como pendente'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marcar como concluída'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Marcar como cancelada'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botões de ação rápida (Maps e Calendar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Botão Maps
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Abrir no Maps'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: activity.latitude != null &&
                              activity.longitude != null
                          ? () async {
                              final success =
                                  await ExternalAppsService.openInMaps(
                                latitude: activity.latitude!,
                                longitude: activity.longitude!,
                                label: activity.title,
                              );

                              if (!success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Não foi possível abrir o Maps'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão Calendar
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Adicionar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        final success =
                            await ExternalAppsService.addToCalendar(activity);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abrindo calendário...'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Não foi possível abrir o calendário'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Sistema de votação (apenas para viagens em grupo)
            if (isGroupTrip)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      "Votação:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildVoteButton(
                      icon: Icons.thumb_up,
                      count: upvotes,
                      isSelected: userVote == 1,
                      color: Colors.green,
                      onTap: () => _vote(activity, 1),
                    ),
                    const SizedBox(width: 8),
                    _buildVoteButton(
                      icon: Icons.thumb_down,
                      count: downvotes,
                      isSelected: userVote == -1,
                      color: Colors.red,
                      onTap: () => _vote(activity, -1),
                    ),
                    const Spacer(),
                    if (activity.opinions.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.comment, size: 16),
                        label: Text("${activity.opinions.length} opiniões"),
                        onPressed: () => _showOpinions(activity),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vote(Activity activity, int vote) async {
    final currentVote = activity.votes[_currentUid];
    final newVote = currentVote == vote ? 0 : vote;
    await _controller.voteActivity(activity.id, _currentUid, newVote);
  }

  void _confirmDelete(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir atividade?"),
        content: Text("Tem certeza que deseja excluir '${activity.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.deleteActivity(activity.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Atividade excluída com sucesso"),
                  ),
                );
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateActivityPage(tripId: widget.tripId, activity: activity),
      ),
    );
  }

  Future<void> _updateStatus(
    Activity activity,
    ActivityStatus newStatus,
  ) async {
    try {
      await _controller.updateActivity(activity.copyWith(status: newStatus));
      if (mounted) {
        String statusText = '';
        switch (newStatus) {
          case ActivityStatus.pending:
            statusText = 'pendente';
            break;
          case ActivityStatus.completed:
            statusText = 'concluída';
            break;
          case ActivityStatus.cancelled:
            statusText = 'cancelada';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Atividade marcada como $statusText")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addOpinion(Activity activity) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar opinião"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Digite sua opinião sobre esta atividade...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _controller.addOpinion(
                  activity.id,
                  controller.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Opinião adicionada com sucesso"),
                    ),
                  );
                }
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  void _showOpinions(Activity activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Opiniões",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: activity.opinions.length,
                itemBuilder: (context, index) {
                  final opinion = activity.opinions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(opinion['userName'][0].toUpperCase()),
                      ),
                      title: Text(
                        opinion['userName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(opinion['text']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
