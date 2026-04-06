import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/models/trip.dart';

void main() {
  testWidgets('Validação visual de um Card de Viagem', (WidgetTester tester) async {
    // Criamos um modelo de viagem fictício para o teste
    final mockTrip = Trip(
      id: '1',
      ownerId: 'user1',
      destination: 'Paris',
      budget: 1000,
      objective: 'Lazer',
      createdAt: DateTime.now(),
    );

    // Renderizamos apenas um Card ou uma estrutura simples que use os dados
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Card(
          child: ListTile(
            title: Text(mockTrip.destination),
            subtitle: Text("Orçamento: R\$ ${mockTrip.budget}"),
          ),
        ),
      ),
    ));

    // Verifica se os dados da viagem aparecem na tela
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Orçamento: R\$ 1000.0'), findsOneWidget);
  });
}
