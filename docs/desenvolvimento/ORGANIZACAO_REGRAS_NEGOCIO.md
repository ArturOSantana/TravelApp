# Organização das Regras de Negócio - Travel App

Este documento explica como o código do Travel App está organizado e onde ficam as diferentes regras de negócio do sistema.

## Arquitetura Geral

O projeto usa uma arquitetura **MVC adaptada para Flutter**, com separação clara entre apresentação, lógica e dados.

```
Telas (UI) → Controllers (Lógica) → Services (Dados) → Models (Estrutura)
```

---

## 1. Models (`lib/models/`)

**O que são:** Classes que representam os dados do sistema.

**Responsabilidades:**
- Definir a estrutura dos dados
- Serializar/deserializar (converter para/de JSON)
- Validações simples de propriedades
- Métodos auxiliares básicos

**Exemplos práticos:**

### Trip (Viagem)
```dart
// Regra: Verificar se usuário é administrador
bool isAdmin(String uid) {
  return uid == ownerId || (members.isNotEmpty && members.first == uid);
}
```

### Expense (Despesa)
```dart
// Regra: Tipos de divisão de despesas
enum SplitType { 
  equal,      // Divide igualmente
  exact,      // Valores exatos
  percentage, // Por porcentagem
  shares      // Por cotas
}
```

### Activity (Atividade)
```dart
// Regra: Estados possíveis de uma atividade
enum ActivityStatus { 
  pending,    // Aguardando
  completed,  // Concluída
  cancelled   // Cancelada
}
```

**Quando usar Models:**
- Criar novas entidades do sistema
- Adicionar campos a entidades existentes
- Definir enums para estados/tipos
- Métodos simples que só dependem dos dados da própria classe

---

## 2. Controllers (`lib/controllers/`)

**O que são:** Classes que contêm a lógica de negócio da aplicação.

**Responsabilidades:**
- Validações complexas
- Cálculos e agregações
- Orquestração de múltiplos services
- Transformação de dados
- Filtros e ordenações

**Exemplos práticos:**

### AuthController
```dart
// Regra: Verificar se email já está cadastrado
Future<bool> isEmailRegistered(String email) async {
  final consulta = await _db
      .collection('users')
      .where('email', isEqualTo: email.trim())
      .get();
  
  return consulta.docs.isNotEmpty;
}

// Regra: Sincronizar nome entre Firebase Auth e Firestore
// Mantém name e userName sempre iguais
await docRef.set({
  'name': nomeNormalizado,
  'userName': nomeNormalizado,
  ...
});
```

### PackingChecklistController
```dart
// Regra: Filtrar itens da mala
List<PackingItem> applyFilters({...}) {
  var filtrados = List<PackingItem>.from(items);
  
  // Filtra por categoria
  if (selectedCategory != 'Todos') {
    filtrados = filtrados.where(...).toList();
  }
  
  // Busca por texto
  if (buscaNormalizada.isNotEmpty) {
    filtrados = filtrados.where(...).toList();
  }
  
  // Ordenação: não marcados primeiro, depois prioridade, depois data
  filtrados.sort((a, b) {
    if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
    if (aPrioridade != bPrioridade) return aPrioridade ? -1 : 1;
    return a.createdAt.compareTo(b.createdAt);
  });
  
  return filtrados;
}
```

**Quando usar Controllers:**
- Implementar lógica de negócio complexa
- Combinar dados de múltiplas fontes
- Fazer cálculos que envolvem vários objetos
- Aplicar regras de validação que dependem do contexto
- Orquestrar chamadas a múltiplos services

---

## 3. Services (`lib/services/`)

**O que são:** Classes que fazem integração com sistemas externos.

**Responsabilidades:**
- Comunicação com Firebase (Firestore, Auth, Storage)
- Integração com APIs externas
- Cache e persistência local
- Operações de infraestrutura
- Tratamento de erros de rede

**Exemplos práticos:**

### PackingChecklistService
```dart
// Regra: Evitar duplicatas ao adicionar template
Future<int> addTemplateItems({...}) async {
  // Busca itens já existentes
  final itensExistentes = await _collection
      .where('tripId', isEqualTo: tripId)
      .get();

  // Cria chave única: "nome|categoria"
  final chavesExistentes = itensExistentes.docs.map((doc) {
    final dados = doc.data();
    return '${dados['name']}|${dados['category']}'.toLowerCase();
  }).toSet();

  // Usa batch para adicionar múltiplos itens de uma vez
  final batch = _db.batch();
  
  for (final item in items) {
    final chaveUnica = '${nome}|${categoria}'.toLowerCase();
    
    // Pula se já existir
    if (chavesExistentes.contains(chaveUnica)) continue;
    
    batch.set(docRef, {...});
  }
  
  await batch.commit();
}
```

### NotificationService
```dart
// Regra: Só agenda notificação se a data for futura
Future<void> scheduleNotification({...}) async {
  if (scheduledDate.isBefore(DateTime.now())) return;
  
  await _notifications.zonedSchedule(...);
}
```

**Quando usar Services:**
- Fazer operações no Firebase
- Chamar APIs externas
- Salvar/ler dados locais
- Enviar notificações
- Fazer upload de arquivos

---

## 4. Screens (`lib/screens/`)

**O que são:** Telas do aplicativo (interface do usuário).

**Responsabilidades:**
- Exibir dados para o usuário
- Capturar entrada do usuário
- Validações de formulário
- Formatação de exibição
- Navegação entre telas

**Exemplos práticos:**

### ExpensesPage
```dart
// Regra: Só mostra aba de divisão se for grupo real
final hasRealGroup = trip.isGroup && groupMemberIds.length >= 2;

return DefaultTabController(
  length: hasRealGroup ? 2 : 1,
  child: Scaffold(
    appBar: AppBar(
      bottom: TabBar(
        tabs: [
          Tab(text: "Histórico"),
          if (hasRealGroup) Tab(text: "Divisão"),
        ],
      ),
    ),
  ),
);
```

### CreateExpensePage
```dart
// Regra: Timeout de 10 segundos para evitar travamento
final docViagem = await FirebaseFirestore.instance
    .collection('trips')
    .doc(widget.tripId)
    .get()
    .timeout(const Duration(seconds: 10));

// Regra: Filtra apenas IDs válidos (não vazios)
final membrosValidosViagem = <String>{
  if (_trip!.ownerId.trim().isNotEmpty) _trip!.ownerId.trim(),
  ..._trip!.members.where((id) => id.trim().isNotEmpty),
};
```

**Quando usar Screens:**
- Criar novas telas
- Adicionar validações de formulário
- Formatar dados para exibição
- Implementar navegação
- Mostrar mensagens de erro/sucesso

---

## Fluxo de Dados Típico

### Exemplo: Criar uma despesa

1. **Screen** (`create_expense_page.dart`)
   - Usuário preenche formulário
   - Valida campos obrigatórios
   - Formata valores de entrada

2. **Controller** (`trip_controller.dart`)
   - Valida regras de negócio (ex: valor > 0)
   - Calcula divisão entre membros
   - Prepara dados para salvar

3. **Service** (`trip_service.dart` ou Firestore direto)
   - Salva no Firebase
   - Trata erros de rede
   - Retorna sucesso/erro

4. **Model** (`expense.dart`)
   - Define estrutura da despesa
   - Serializa para JSON
   - Deserializa do Firestore

---

## Regras de Negócio Importantes

### Autenticação
- **Onde:** `AuthController`
- Email e senha são sempre normalizados (trim)
- `name` e `userName` devem ser sempre iguais
- Em caso de erro ao verificar email, assume que existe (segurança)

### Viagens em Grupo
- **Onde:** `Trip` model + várias screens
- Máximo de 20 membros por viagem
- Grupo real = `isGroup == true` E `members.length >= 2`
- Apenas o dono pode deletar a viagem

### Divisão de Despesas
- **Onde:** `Expense` model + `ExpensesPage`
- 4 tipos de divisão: igual, exata, porcentagem, cotas
- Conversão automática de moedas
- Cálculo de "quem deve para quem"

### Lista de Mala
- **Onde:** `PackingChecklistController` + `PackingChecklistService`
- Chave única: `nome|categoria` (lowercase)
- Ordenação: não marcados → prioridade → data
- Batch write para performance

### Notificações
- **Onde:** `NotificationService`
- Só agenda se data for futura
- Timezone: America/Sao_Paulo
- Permissões específicas por plataforma

### Cache e Performance
- **Onde:** `main.dart` + `MemoryManagerService`
- Firebase cache: 1MB a 100MB
- Dispositivos antigos recebem valores menores
- Timeout de 10 segundos em operações críticas

---

## Boas Práticas

### ✅ Faça

- Coloque validações simples nos Models
- Coloque lógica complexa nos Controllers
- Use Services apenas para integração
- Mantenha Screens focadas na UI
- Adicione comentários explicando o "porquê"
- Use nomes descritivos em português
- Trate erros específicos

### ❌ Evite

- Lógica de negócio nas Screens
- Acesso direto ao Firebase nas Screens
- Comentários genéricos tipo "// TODO"
- Variáveis não utilizadas
- Try-catch genérico sem tratamento
- Misturar português e inglês
- Código duplicado

---

## Exemplos de Onde Colocar Novas Regras

### "Usuário premium pode criar viagens ilimitadas"
- **Model:** `UserModel` - adicionar campo `isPremium`
- **Controller:** `TripController` - validar limite antes de criar
- **Screen:** `CreateTripPage` - mostrar mensagem de upgrade

### "Despesas acima de R$ 1000 precisam de aprovação"
- **Model:** `Expense` - adicionar campo `needsApproval`
- **Controller:** `TripController` - lógica de aprovação
- **Service:** Salvar no Firestore com status pendente
- **Screen:** Mostrar badge "Aguardando aprovação"

### "Notificar 1 dia antes da viagem"
- **Service:** `NotificationService` - agendar notificação
- **Controller:** `TripController` - calcular data correta
- **Screen:** `TripDashboardPage` - botão para ativar

---

## Conclusão

A organização do código segue uma hierarquia clara:

```
Models (estrutura) 
  ↓
Services (dados)
  ↓
Controllers (lógica)
  ↓
Screens (interface)
```

Cada camada tem responsabilidades bem definidas. Ao adicionar novas funcionalidades, identifique em qual camada ela se encaixa melhor e siga os padrões existentes.

**Dúvidas?** Consulte exemplos similares no código ou este documento.