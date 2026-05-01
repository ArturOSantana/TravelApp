import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/user_model.dart';
import '../controllers/trip_controller.dart';
import '../services/subscription_service.dart';
import 'premium_upgrade_page.dart';

class GroupMembersPage extends StatefulWidget {
  final Trip trip;
  const GroupMembersPage({super.key, required this.trip});

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final controller = TripController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isAdmin(Trip trip) => trip.isAdmin(currentUid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Membros do Grupo"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin(widget.trip))
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showInviteDialog(context),
              tooltip: "Convidar Membro",
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.trip.id)
            .snapshots(),
        builder: (context, tripSnapshot) {
          if (tripSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!tripSnapshot.hasData || !tripSnapshot.data!.exists) {
            return const Center(
              child: Text("Erro ao carregar dados da viagem."),
            );
          }

          final liveTrip = Trip.fromFirestore(tripSnapshot.data!);
          final memberIds = <String>{
            if (liveTrip.ownerId.trim().isNotEmpty) liveTrip.ownerId.trim(),
            ...liveTrip.members
                .where((id) => id.trim().isNotEmpty)
                .map((id) => id.trim()),
          }.toList();
          final isAdm = _isAdmin(liveTrip);

          return FutureBuilder<List<UserModel>>(
            future: controller.getTripMembers(memberIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting &&
                  !userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Se não co
              if (userSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar membros: ${userSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }

              final members = userSnapshot.data ?? [];

              // Se não há membros
              if (members.isEmpty) {
                return const Center(child: Text('Nenhum membro encontrado.'));
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.deepPurple.withValues(alpha: 0.05),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.group,
                          size: 50,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${memberIds.length} ${memberIds.length == 1 ? 'Pessoa' : 'Pessoas'} na Viagem",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isAdm)
                          const Text(
                            "Você é o Administrador",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            "Apenas o ADM pode gerenciar membros.",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final bool isMemberOwner = liveTrip.ownerId.isNotEmpty
                            ? member.uid == liveTrip.ownerId
                            : (memberIds.isNotEmpty &&
                                member.uid == memberIds.first);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getMemberColor(index),
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              member.uid == currentUid
                                  ? "${member.name} (Você)"
                                  : member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              member.email.isEmpty ? "Convidado" : member.email,
                            ),
                            trailing: isMemberOwner
                                ? const BadgeADM()
                                : (isAdm
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.person_remove,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _confirmRemove(context, member),
                                      )
                                    : null),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    // 🔒 VERIFICAÇÃO PREMIUM: Limitar membros por viagem
    final canAdd = await SubscriptionService.canAddMember(widget.trip.id);
    if (!canAdd) {
      if (!mounted) return;
      _showPremiumRequiredDialog();
      return;
    }

    if (!mounted) return;
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.trip.id,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.trip.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Código copiado!")),
              );
              Navigator.pop(context);
            },
            child: const Text("Copiar Código"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await controller.removeMember(widget.trip.id, member.uid);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${member.name} foi removido do grupo.'),
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erro ao remover membro: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Remover", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getMemberColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 10),
            const Text("Premium Necessário"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Você atingiu o limite de membros do plano gratuito (3 pessoas).",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "Com Premium você tem:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem("Membros ilimitados por viagem"),
                  _buildBenefitItem("Viagens ilimitadas"),
                  _buildBenefitItem("Insights avançados com IA"),
                  _buildBenefitItem("Suporte prioritário"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Agora não"),
          ),
          ElevatedButton(
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
            child: const Text("Fazer Upgrade"),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: Text(
        "• $text",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class BadgeADM extends StatelessWidget {
  const BadgeADM({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        "ADM",
        style: TextStyle(
          fontSize: 10,
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
