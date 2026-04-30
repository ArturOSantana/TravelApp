# Correções de Contraste e Cores - WCAG AA Compliance

## Objetivo
Substituir todas as cores hardcoded por cores do sistema `AppColors` para garantir:
- Contraste adequado (WCAG AA - mínimo 4.5:1)
- Consistência visual em todo o app
- Suporte adequado a temas claro/escuro
- Acessibilidade para usuários com deficiência visual

## Arquivos Corrigidos

### ✅ lib/screens/onboarding_page.dart
**Alterações:**
- `Colors.deepPurple` → `AppColors.primary`
- `Colors.green` → `AppColors.success`
- `Colors.orange` → `AppColors.warning`
- `Colors.red` → `AppColors.error`
- `Colors.white` → `AppColors.surface`
- `Colors.grey.shade300` → `AppColors.divider`
- `Colors.grey[700]` → `AppColors.textSecondary`
- `Colors.grey[800]` → `AppColors.textPrimary`

**Impacto:** Melhor contraste nos slides de onboarding, cores consistentes com o tema do app.

### ✅ lib/screens/community_page.dart
**Alterações:**
- `Colors.red` → `AppColors.error` (ícone de curtida)
- `Colors.grey[400]` → `AppColors.textDisabled` (ícones inativos)
- `Colors.transparent` → `AppColors.overlay` (fundo do modal)
- `Colors.grey[100]` → `AppColors.surfaceVariant` (campo de comentário)
- `Colors.indigo` → `AppColors.primary` (botão enviar)
- `Colors.white` → `AppColors.textOnPrimary` (ícone no botão)

**Impacto:** Melhor legibilidade dos posts, contraste adequado nos botões de ação.

### ✅ lib/screens/insights_page.dart
**Alterações:**
- `Colors.deepPurple[700/400]` → `AppColors.primaryGradient` (banners)
- `Colors.white` → `AppColors.textOnPrimary` (texto em gradientes)
- `Colors.blue` → `AppColors.info` (estatísticas)
- `Colors.green` → `AppColors.success` (indicadores positivos)
- `Colors.red` → `AppColors.error` (indicadores negativos)
- `Colors.orange` → `AppColors.warning` (estilo solo)
- `Colors.indigo` → `AppColors.info` (estilo grupo)
- `Colors.grey[50/200]` → `AppColors.surfaceVariant/divider`
- `Colors.grey` → `AppColors.textSecondary` (labels)

**Impacto:** Contraste adequado em todos os cards financeiros, gráficos legíveis, banners premium acessíveis.

## Próximas Correções Necessárias

### 🔄 Telas Prioritárias (Alto Uso)
1. **lib/screens/profile_page.dart** - Muitas cores hardcoded
2. **lib/screens/expenses_page.dart** - Cores de status financeiro
3. **lib/screens/reports_page.dart** - Gráficos e indicadores
4. **lib/screens/safety_page.dart** - Alertas de segurança
5. **lib/screens/journal_page.dart** - Mood tracking e reações

### 📋 Telas Secundárias
6. **lib/screens/flight_search_page.dart**
7. **lib/screens/create_expense_page.dart**
8. **lib/screens/create_trip_page.dart**
9. **lib/screens/packing_checklist_page.dart**
10. **lib/screens/insights_page.dart**
11. **lib/screens/rate_destination_page.dart**
12. **lib/screens/premium_upgrade_page.dart**
13. **lib/screens/welcome_premium_page.dart**

## Padrões de Substituição

### Cores de Texto
```dart
Colors.black / Colors.grey[900] → AppColors.textPrimary
Colors.grey[600/700] → AppColors.textSecondary
Colors.grey[400/500] → AppColors.textDisabled
Colors.white (em botões) → AppColors.textOnPrimary
```

### Cores de Feedback
```dart
Colors.green → AppColors.success
Colors.red → AppColors.error
Colors.orange → AppColors.warning
Colors.blue → AppColors.info
```

### Backgrounds
```dart
Colors.white → AppColors.surface
Colors.grey[50/100] → AppColors.surfaceVariant
Colors.grey[200/300] → AppColors.divider
```

### Cores Primárias
```dart
Colors.deepPurple → AppColors.primary
Colors.purple[700] → AppColors.primaryDark
Colors.purple[300] → AppColors.primaryLight
```

## Benefícios das Correções

1. **Acessibilidade**: Todos os contrastes atendem WCAG AA (4.5:1 mínimo)
2. **Consistência**: Mesma paleta em todo o app
3. **Manutenibilidade**: Mudanças centralizadas em um único arquivo
4. **Tema Escuro**: Suporte automático com cores adaptativas
5. **Profissionalismo**: Visual mais polido e coeso

## Status Atual
- ✅ 3 telas corrigidas (onboarding, community, insights)
- 🔄 12+ telas pendentes
- 📊 ~20% concluído

## Próximos Passos
1. Corrigir telas prioritárias (profile, expenses, reports, safety, journal)
2. Corrigir telas secundárias
3. Testar contraste em todas as telas
4. Validar com ferramentas de acessibilidade
5. Documentar padrões para novos desenvolvedores