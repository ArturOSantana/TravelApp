import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../controllers/trip_controller.dart';
import 'itinerary_page.dart';
import 'expenses_page.dart';
import 'journal_page.dart';
import 'safety_page.dart';
import 'group_members_page.dart';

class TripDashboardPage extends StatelessWidget {
  final Trip trip;

  const TripDashboardPage({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TripController();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final bool isAdm = trip.ownerId.isNotEmpty 
        ? currentUid == trip.ownerId 
        : (trip.members.isNotEmpty && trip.members.first == currentUid);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.destination),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupMembersPage(trip: trip))),
            tooltip: "Ver Membros",
          ),
          if (isAdm)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () => _showInviteDialog(context),
              tooltip: "Convidar Amigos",
            ),
          if (isAdm && trip.status != 'completed')
            TextButton.icon(
              onPressed: () => _showFinishDialog(context, controller),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("Concluir", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: trip.status == 'completed' ? Colors.grey : Colors.deepPurple,
                      child: Icon(
                        trip.status == 'completed' ? Icons.archive : Icons.flight_takeoff, 
                        color: Colors.white, 
                        size: 30
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.destination,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Status: ${trip.status == 'active' ? 'Em andamento' : trip.status == 'completed' ? 'Concluída' : 'Planejada'}",
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                          if (trip.isGroup)
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupMembersPage(trip: trip))),
                              child: Text("${trip.members.length} membros no grupo (Ver)", style: const TextStyle(color: Colors.deepPurple, fontSize: 12, decoration: TextDecoration.underline)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Gerenciamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildOptionCard(
                context, 
                Icons.calendar_month, 
                "Roteiro Inteligente", 
                "Organize atividades e vote em grupo",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.account_balance_wallet, 
                "Controle Financeiro", 
                "Gastos e divisão automática",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExpensesPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.auto_stories, 
                "Diário de Viagem", 
                "Registre memórias e sentimentos",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => JournalPage(tripId: trip.id)))
              ),
              _buildOptionCard(
                context, 
                Icons.gpp_good, 
                "Segurança e SOS", 
                "Compartilhamento de localização",
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPage(tripId: trip.id)))
              ),
            ],
          ),
        ),
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
            const Text("Compartilhe o código abaixo para convidar seus amigos:"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(
                trip.id, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: trip.id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código copiado!")));
            },
            icon: const Icon(Icons.copy),
            tooltip: "Copiar Código",
          ),
          Builder(
            builder: (buttonContext) {
              return ElevatedButton.icon(
                onPressed: () async {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  final String text = "Ei! Vamos viajar juntos para ${trip.destination}?\n\n"
                      "Baixe o Travel App e entre no meu grupo usando o código:\n"
                      "${trip.id}";
                  
                  await Share.share(
                    text, 
                    subject: "Convite de Viagem",
                    sharePositionOrigin: box != null 
                        ? box.localToGlobal(Offset.zero) & box.size 
                        : null,
                  );
                }, 
                icon: const Icon(Icons.share),
                label: const Text("Compartilhar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              );
            }
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, TripController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Concluir Viagem?"),
        content: const Text("Isso gerará seu relatório de análise final."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await controller.updateTripStatus(trip.id, 'completed');
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Concluir"),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
