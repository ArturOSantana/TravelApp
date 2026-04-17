import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../models/packing_checklist.dart';
import '../controllers/trip_controller.dart';
import 'create_activity_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;
  const ItineraryPage({super.key, required this.tripId});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final TripController controller = TripController();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // TODO: Implementar visualização em mapa
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nova Atividade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateActivityPage(tripId: widget.tripId),
            ),
          );
        },
      ),
      body: StreamBuilder<List<Activity>>(
        stream: controller.getActivities(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data ?? [];

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              String dateKey = grouped.keys.elementAt(index);
              List<Activity> dayActivities = grouped[dateKey]!;
              DateTime date = dayActivities.first.time;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(date),
                  const SizedBox(height: 16),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = dayActivities.removeAt(oldIndex);
                        dayActivities.insert(newIndex, item);
                      });
                    },
                    children: dayActivities
                        .map((activity) => _buildActivityCard(
                              key: ValueKey(activity.id),
                              activity: activity,
                              uid: uid,
                              controller: controller,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String dayName = DateFormat('EEEE', 'pt_BR').format(date);
    String dayMonth = DateFormat('dd/MM').format(date);
    bool isToday = DateFormat('dd/MM/yyyy').format(date) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isToday 
                ? const LinearGradient(colors: [Colors.deepPurple, Colors.deepPurpleAccent])
                : null,
              color: isToday ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Text(
              dayMonth,
              style: TextStyle(
                color: isToday ? Colors.white : Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName.toUpperCase(),
                style: TextStyle(
                  color: isToday ? Colors.deepPurple : Colors.black54,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (isToday)
                const Text(
                  "HOJE",
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required Key key,
    required Activity activity,
    required String uid,
    required TripController controller,
  }) {
    int upVotes = activity.votes.values.where((v) => v == 1).length;
    int myVote = activity.votes[uid] ?? 0;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getCategoryIcon(activity.category),
                      color: Colors.deepPurple, size: 24),
                ),
                title: Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF2D3142),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(activity.time),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: [
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.description != null && activity.description!.isNotEmpty)
                          Text(activity.description!, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        _buildVotingAndComments(activity, uid, upVotes, myVote, controller),
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
          .where('tripId', isEqualTo: widget.tripId)
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: isAllDone ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Icon(
                isAllDone ? Icons.check_circle : Icons.shopping_bag_outlined,
                color: isAllDone ? Colors.green[700] : Colors.orange[700],
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAllDone 
                    ? "Tudo pronto para esta atividade!" 
                    : "Faltam $pendingCount itens no seu checklist para essa atividade.",
                  style: TextStyle(
                    color: isAllDone ? Colors.green[900] : Colors.orange[900],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isAllDone ? Colors.green[300] : Colors.orange[300],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVotingAndComments(Activity activity, String uid, int up, int myVote, TripController controller) {
    return Column(
      children: [
        Row(
          children: [
            const Text("Grupo concorda?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            _voteCircle(Icons.thumb_up, Colors.green, up, myVote == 1, 
              () => controller.voteActivity(activity.id, uid, 1)),
            const SizedBox(width: 8),
            _voteCircle(Icons.thumb_down, Colors.red, null, myVote == -1, 
              () => controller.voteActivity(activity.id, uid, -1)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMiniComments(activity, controller),
      ],
    );
  }

  Widget _voteCircle(IconData icon, Color color, int? count, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? color : Colors.grey),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text("$count", style: TextStyle(color: active ? color : Colors.grey, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMiniComments(Activity activity, TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activity.opinions.take(2).map((op) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            "${op['userName']}: ${op['text']}",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: "Adicionar opinião...",
            hintStyle: const TextStyle(fontSize: 12),
            isDense: true,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            suffixIcon: const Icon(Icons.send, size: 18, color: Colors.deepPurple),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) controller.addOpinion(activity.id, val.trim());
          },
        ),
      ],
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.map_outlined, size: 70, color: Colors.deepPurple.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text("Organize sua jornada", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Toque no botão abaixo para criar seu primeiro roteiro.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

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
