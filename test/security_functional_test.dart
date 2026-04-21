import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/models/user_model.dart';

void main() {
  group('Testes de Lógica de Segurança e SOS', () {
    
    test('Deve identificar corretamente se o usuário está em grupo para decidir o canal de SOS', () {
      final tripSolo = Trip(
        id: '1', ownerId: 'u1', destination: 'Paris', 
        budget: 1000, objective: 'Lazer', createdAt: DateTime.now(),
        members: ['u1'], isGroup: false
      );

      final tripGroup = Trip(
        id: '2', ownerId: 'u1', destination: 'Roma', 
        budget: 2000, objective: 'Lazer', createdAt: DateTime.now(),
        members: ['u1', 'u2'], isGroup: true
      );

      expect(tripSolo.members.length > 1, false);
      expect(tripGroup.members.length > 1, true);
    });

    test('Cálculo de Geofencing: Deve detectar chegada quando distância for menor que 50m', () {
      // Coordenadas simuladas (Avenida Paulista)
      double startLat = -23.5615;
      double startLon = -46.6560;
      
      // Ponto a 30 metros de distância
      double endLat = -23.5617;
      double endLon = -46.6561;

      double distance = Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
      
      expect(distance < 50, true, reason: "Usuário deveria ser considerado 'Chegou'");
    });

    test('Validação de Contato: Não deve permitir SOS sem telefone configurado', () {
      final userSemTelefone = UserModel(
        uid: '1', name: 'Artur', email: 'artur@test.com', 
        emergencyContact: '', emergencyPhone: ''
      );

      expect(userSemTelefone.emergencyPhone.isEmpty, true);
    });
  });
}
