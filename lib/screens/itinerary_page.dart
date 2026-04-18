import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/activity.dart';
import '../models/packing_checklist.dart';
import '../controllers/trip_controller.dart';
import 'create_activity_page.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TripController controller = TripController();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Roteiro de Viagem"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nova Atividade",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateActivityPage(tripId: widget.tripId),
            ),
          );
        },
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<Activity>>(
              stream: controller.getActivities(widget.tripId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var activities = snapshot.data ?? [];

                if (_selectedCategory != 'Todos') {
                  activities = activities
                      .where((a) =>
                          a.category.toLowerCase() ==
                          _selectedCategory.toLowerCase())
                      .toList();
                }

                if (activities.isEmpty) {
                  return _buildEmptyState();
                }

                // Agrupar atividades por dia
                Map<String, List<Activity>> grouped = {};
                for (var act in activities) {
                  String dateKey = DateFormat('dd/MM/yyyy').format(act.time);
                  grouped.putIfAbsent(dateKey, () => []).add(act);
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    String dateKey = grouped.keys.elementAt(index);
                    List<Activity> dayActivities = grouped[dateKey]!;
                    DateTime date = dayActivities.first.time;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(date, dayActivities.length),
                        const SizedBox(height: 10),
                        _ActivitiesList(
                          activities: dayActivities,
                          uid: uid,
                          tripId: widget.tripId,
                          controller: controller,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<String>>(
      stream: controller.watchTripCategories(widget.tripId),
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
              final filter = categories[index];
              final isSelected = _selectedCategory == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(filter),
                  onSelected: (val) {
                    setState(() => _selectedCategory = filter);
                  },
                  selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
                  checkmarkColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, int count) {
    String dayName = DateFormat('EEEE', 'pt_BR').format(date);
    String dayMonth = DateFormat('dd/MM').format(date);
    bool isToday = DateFormat('dd/MM/yyyy').format(date) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isToday ? Colors.deepPurple : Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dayMonth,
              style: TextStyle(
                color: isToday ? Colors.white : Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "$count ${count == 1 ? 'atividade' : 'atividades'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isToday)
            const Chip(
              label: Text("HOJE",
                  style: TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.orange,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Nenhuma atividade encontrada",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ActivitiesList extends StatefulWidget {
  final List<Activity> activities;
  final String uid;
  final String tripId;
  final TripController controller;

  const _ActivitiesList({
    required this.activities,
    required this.uid,
    required this.tripId,
    required this.controller,
  });

  @override
  State<_ActivitiesList> createState() => _ActivitiesListState();
}

class _ActivitiesListState extends State<_ActivitiesList> {
  late List<Activity> _localActivities;

  @override
  void initState() {
    super.initState();
    _localActivities = List.from(widget.activities);
  }

  @override
  void didUpdateWidget(_ActivitiesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza com a stream externa apenas se os IDs mudarem (evita flicker no reorder)
    final oldIds = oldWidget.activities.map((a) => a.id).join();
    final newIds = widget.activities.map((a) => a.id).join();
    if (oldIds != newIds) {
      setState(() {
        _localActivities = List.from(widget.activities);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _localActivities.length,
      itemBuilder: (context, index) {
        final activity = _localActivities[index];
        final nextActivity = (index + 1 < _localActivities.length) ? _localActivities[index+1] : null;

        return Column(
          key: ValueKey(activity.id),
          children: [
            _ActivityCard(
              activity: activity,
              uid: widget.uid,
              tripId: widget.tripId,
              controller: widget.controller,
              index: index,
            ),
            if (nextActivity != null) 
              _buildRouteInfo(activity, nextActivity),
          ],
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _localActivities.removeAt(oldIndex);
          _localActivities.insert(newIndex, item);
        });
        widget.controller.reorderActivities(_localActivities);
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 5,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: child,
        );
      },
    );
  }

  Widget _buildRouteInfo(Activity start, Activity end) {
    if (start.latitude == null || start.longitude == null || end.latitude == null || end.longitude == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openMapRoute(start, end),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_car, size: 14, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                "Ver rota e tempo entre locais",
                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 10, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  void _openMapRoute(Activity start, Activity end) async {
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=driving"
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final String uid;
  final String tripId;
  final TripController controller;
  final int index;

  const _ActivityCard({
    super.key,
    required this.activity,
    required this.uid,
    required this.tripId,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    int upVotes = activity.votes.values.where((v) => v == 1).length;
    int myVote = activity.votes[uid] ?? 0;

    return Dismissible(
      key: ValueKey("dismiss_${activity.id}"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Excluir Atividade?"),
            content: const Text("Deseja remover esta atividade do roteiro?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Não")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Sim", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) => controller.deleteActivity(activity.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getCategoryIcon(activity.category),
                      color: Colors.deepPurple, size: 22),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator, color: Colors.grey),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(activity.time),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.description != null &&
                            activity.description!.isNotEmpty) ...[
                          Text(activity.description!,
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 16),
                        ],
                        _buildVotingAndComments(context, activity, upVotes, myVote),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateActivityPage(
                                  tripId: tripId,
                                  activity: activity,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Editar Atividade"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildChecklistStatus(activity),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistStatus(Activity activity) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('packing_items')
          .where('tripId', isEqualTo: tripId)
          .where('category', isEqualTo: _capitalize(activity.category))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data!.docs
            .map((doc) => PackingItem.fromFirestore(doc))
            .toList();
        final pendingCount = items.where((item) => !item.isChecked).length;
        bool isAllDone = pendingCount == 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isAllDone ? Colors.green.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
            border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.03))),
          ),
          child: Row(
            children: [
              Icon(
                isAllDone ? Icons.check_circle : Icons.shopping_bag_outlined,
                color: isAllDone ? Colors.green : Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAllDone
                      ? "Checklist completo para esta atividade!"
                      : "Faltam $pendingCount itens no seu checklist.",
                  style: TextStyle(
                    color: isAllDone ? Colors.green[800] : Colors.orange[800],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVotingAndComments(BuildContext context, Activity activity, int up, int myVote) {
    return Column(
      children: [
        Row(
          children: [
            const Text("Grupo concorda?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            _voteCircle(Icons.thumb_up, Colors.green, up, myVote == 1,
                () => controller.voteActivity(activity.id, uid, 1)),
            const SizedBox(width: 8),
            _voteCircle(Icons.thumb_down, Colors.red, null, myVote == -1,
                () => controller.voteActivity(activity.id, uid, -1)),
          ],
        ),
        const SizedBox(height: 12),
        _buildMiniComments(activity),
      ],
    );
  }

  Widget _voteCircle(IconData icon, Color color, int? count, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.grey),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text("$count",
                  style: TextStyle(
                      fontSize: 12,
                      color: active ? color : Colors.grey,
                      fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMiniComments(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activity.opinions.take(2).map((op) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  children: [
                    TextSpan(text: "${op['userName']}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: op['text']),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: "Adicionar opinião...",
            isDense: true,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            suffixIcon: const Icon(Icons.send, size: 16, color: Colors.deepPurple),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) controller.addOpinion(activity.id, val.trim());
          },
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'praia': return Icons.beach_access;
      case 'trilha': return Icons.terrain;
      case 'cidade': return Icons.location_city;
      case 'restaurante': return Icons.restaurant;
      case 'museu': return Icons.museum;
      case 'aventura': return Icons.explore;
      case 'compras': return Icons.shopping_bag;
      default: return Icons.event;
    }
  }
}
