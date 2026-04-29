# Melhorias do Dark Mode - Pendentes

## ✅ Já Corrigido:
- `lib/screens/community_page.dart` - Cores do tema aplicadas
- `lib/screens/flight_search_page.dart` - Campos e botões corrigidos
- `lib/screens/hotel_search_page.dart` - Campos e botões corrigidos

## 🔧 Precisa Corrigir:

### Telas de Viagem:
1. `lib/screens/trip_dashboard_page.dart` - Cores fixas
2. `lib/screens/itinerary_page.dart` - Verificar cores
3. `lib/screens/expenses_page.dart` - Verificar cores
4. `lib/screens/packing_checklist_page.dart` - Verificar cores
5. `lib/screens/journal_page.dart` - Verificar cores
6. `lib/screens/safety_page.dart` - Verificar cores
7. `lib/screens/group_members_page.dart` - Verificar cores
8. `lib/screens/trips_page.dart` - Verificar cores

### Outras Telas:
9. `lib/screens/dashboard_page.dart` - Verificar cores
10. `lib/screens/create_trip_page.dart` - Verificar cores
11. `lib/screens/create_activity_page.dart` - Verificar cores
12. `lib/screens/create_expense_page.dart` - Verificar cores
13. `lib/screens/create_journal_entry_page.dart` - Verificar cores

## 🎨 Padrão de Correção:

### Substituir:
- `Colors.white` → `Theme.of(context).colorScheme.surface`
- `Colors.black` → `Theme.of(context).colorScheme.onSurface`
- `Colors.grey[100]` → `Theme.of(context).colorScheme.surfaceVariant`
- `Colors.black54` → `Theme.of(context).colorScheme.onSurfaceVariant`
- `Colors.black87` → `Theme.of(context).colorScheme.onSurface`
- `const Color(0xFFF8F9FD)` → Remover (usar padrão do Scaffold)
- `backgroundColor: Colors.white` → Remover (usar padrão do AppBar)
- `foregroundColor: Colors.black` → Remover (usar padrão do AppBar)

### Cores Específicas (manter mas adaptar):
- `Colors.indigo` → `Theme.of(context).colorScheme.primary`
- `Colors.red` → `Theme.of(context).colorScheme.error`
- `Colors.green` → `Colors.green` (pode manter para sucesso)
- `Colors.orange` → `Colors.orange` (pode manter para aviso)

## 📝 Próximos Passos:
1. Corrigir trip_dashboard_page.dart
2. Testar no modo escuro
3. Corrigir outras telas conforme necessário
4. Documentar mudanças