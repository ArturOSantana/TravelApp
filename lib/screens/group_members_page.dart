import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';

class GroupMembersPage extends StatefulWidget {
  final Trip trip;
  const GroupMembersPage({super.key, required this.trip});

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final controller = TripController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get isAdm {
    return widget.trip.ownerId.isNotEmpty 
        ? currentUid == widget.trip.ownerId 
        : (widget.trip.members.isNotEmpty && widget.trip.members.first == currentUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Membros do Grupo"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (isAdm)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showInviteDialog(context),
              tooltip: "Convidar Membro",
            ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: controller.getTripMembers(widget.trip.members),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.deepPurple.withOpacity(0.05),
                child: Column(
                  children: [
                    const Icon(Icons.group, size: 50, color: Colors.deepPurple),
                    const SizedBox(height: 10),
                    Text(
                      "${members.length} Pessoas na Viagem",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isAdm)
                      const Text("Você é o Administrador", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    else
                      const Text("Apenas o ADM pode gerenciar membros.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    // O dono original ou o primeiro da lista (se ownerId for vazio) é o ADM
                    bool isMemberOwner = widget.trip.ownerId.isNotEmpty 
                        ? member.uid == widget.trip.ownerId 
                        : (widget.trip.members.indexOf(member.uid) == 0);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMemberColor(index),
                          child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(member.email),
                        trailing: isMemberOwner 
                          ? const BadgeADM()
                          : (isAdm ? IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.red),
                              onPressed: () => _confirmRemove(context, member),
                            ) : null), // Se não for ADM, o trailing é null (membro só olha)
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Convidar para o Grupo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Compartilhe o código abaixo com seus amigos:"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(widget.trip.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.trip.id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código copiado!")));
              Navigator.pop(context);
            }, 
            child: const Text("Copiar Código")
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Membro"),
        content: Text("Deseja realmente remover ${member.name} do grupo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await controller.removeMember(widget.trip.id, member.uid);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {}); // Recarrega a lista
              }
            },
            child: const Text("Remover", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getMemberColor(int index) {
    List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    return colors[index % colors.length];
  }
}

class BadgeADM extends StatelessWidget {
  const BadgeADM({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(5)),
      child: const Text("ADM", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
    );
  }
}
