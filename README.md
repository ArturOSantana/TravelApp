# Travel App - Sistema de Planejamento e Gestão de Viagens

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.0-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-Academic-green)

**Trabalho de Conclusão de Curso**  
**ETEC - Desenvolvimento de Sistemas**  
**Versão 1.0.0 | 2026**

[Documentação](docs/README.md) • [Início Rápido](#início-rápido) • [Arquitetura](#arquitetura) • [Contribuir](docs/desenvolvimento/CONTRIBUTING.md)

</div>

---

## Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Problema e Solução](#problema-e-solução)
- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Início Rápido](#início-rápido)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Documentação](#documentação)
- [Testes](#testes)
- [Roadmap](#roadmap)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

---

## Sobre o Projeto

O **Travel App** é uma aplicação multiplataforma desenvolvida em Flutter que unifica todas as necessidades de planejamento e gestão de viagens em uma única plataforma. O sistema foi projetado para atender tanto viajantes individuais quanto grupos, oferecendo ferramentas robustas para organização logística, controle financeiro compartilhado, documentação de experiências e recursos de segurança.

### Contexto

O setor de turismo movimenta bilhões anualmente, com crescente demanda por ferramentas digitais que facilitem a experiência do viajante. A pandemia acelerou a digitalização do setor, criando oportunidades para soluções inovadoras que integrem múltiplas funcionalidades em uma única plataforma.

### Diferenciais

- **Integração Completa**: Todas as funcionalidades essenciais em um único aplicativo
- **Colaboração em Tempo Real**: Sincronização instantânea entre membros do grupo via Firebase
- **Gestão Financeira Avançada**: Algoritmo automático de divisão de despesas com suporte a múltiplas moedas
- **Segurança**: Recursos de emergência, check-ins de segurança e compartilhamento de localização
- **Multiplataforma**: Disponível para Android, iOS, Web e Desktop
- **Offline-First**: Funcionamento sem conexão com sincronização automática

---

## Problema e Solução

### Problema Identificado

Viajantes enfrentam diversos desafios ao planejar e executar viagens:

1. **Coordenação de Grupos**: Dificuldade em sincronizar planos entre múltiplos participantes
2. **Gestão Financeira**: Complexidade na divisão de despesas e controle de orçamento
3. **Organização de Informações**: Dados dispersos em múltiplas ferramentas (planilhas, apps, notas)
4. **Preservação de Memórias**: Falta de uma forma estruturada de documentar experiências
5. **Segurança**: Ausência de recursos de emergência e compartilhamento de localização

### Solução Proposta

Uma plataforma unificada que integra:

- **Planejamento Colaborativo**: Sistema de viagens em grupo com permissões e votação democrática
- **Controle Financeiro Inteligente**: Divisão automática de despesas com conversão de moedas
- **Documentação Digital**: Diário de viagem com fotos, localização e análise de humor
- **Recursos de Segurança**: Botão de pânico, check-ins automáticos e contatos de emergência
- **Sugestões Inteligentes**: Integração com APIs para recomendações de locais e atividades

---

## Funcionalidades

### 1. Gestão de Viagens

**Módulo Central de Planejamento**

- Criação de viagens individuais ou em grupo (até 20 membros)
- Suporte a viagens planejadas (com datas definidas) ou nômades (sem data de término)
- Sistema de convites por código único
- Controle de permissões (administrador e membros)
- Acompanhamento de orçamento em tempo real
- Status da viagem (planejada, ativa, concluída)
- Foto de capa personalizável

**Implementação Técnica:**
```dart
class Trip {
  final String id;
  final String ownerId;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final String baseCurrency;
  final bool isGroup;
  final List<String> members;
  final bool isNomad;
  final String status;
}
```

### 2. Itinerário e Atividades

**Organização Cronológica de Atividades**

- Criação de atividades com data, horário e localização
- Categorização (transporte, hospedagem, alimentação, passeio, cultura, etc.)
- Sistema de votação democrática para aprovação em grupos
- Visualização em lista ordenada por data
- Notificações de atividades próximas
- Integração com Google Maps e Apple Maps
- Exportação para Google Calendar e Apple Calendar

**Sugestões Inteligentes (Geoapify API):**
- Atrações turísticas próximas ao destino
- Restaurantes e cafés recomendados
- Opções de entretenimento local
- Filtros por categoria e distância
- Avaliações e informações detalhadas

### 3. Controle Financeiro

**Gestão Completa de Despesas**

- Registro de despesas por categoria
- Algoritmo automático de divisão entre membros
- Suporte a múltiplas moedas com conversão em tempo real (ExchangeRate API)
- Relatório de balanço ("quem deve para quem")
- Exportação de relatórios em PDF
- Compartilhamento de cobranças via WhatsApp
- Gráficos de distribuição de gastos
- Acompanhamento de orçamento vs gastos reais

**Algoritmo de Divisão:**
```dart
// Calcula automaticamente quanto cada membro deve pagar
// Considera quem pagou e quem deve dividir
// Otimiza transações para minimizar número de pagamentos
```

### 4. Diário de Viagem

**Documentação Digital de Experiências**

- Criação de entradas com texto rico, fotos e localização
- Análise de humor (mood tracking) para cada entrada
- Galeria de fotos organizada por viagem
- Álbum público compartilhável via link único
- Busca por localização e data
- Reações e comentários de membros do grupo
- Exportação de entradas em PDF
- Compartilhamento em redes sociais

**Recursos de Privacidade:**
- Controle de visibilidade (público/privado)
- Senha para álbuns compartilhados
- Expiração de links
- Opção de desativar comentários

### 5. Biblioteca de Serviços

**Catálogo Pessoal de Estabelecimentos**

- Registro de hospedagens, restaurantes, transportes e atrações
- Avaliação com sistema de estrelas
- Upload de fotos
- Informações de custo médio e localização
- Categorização e busca avançada
- Importação de recomendações da comunidade

### 6. Comunidade

**Rede Social de Viajantes**

- Feed público de recomendações
- Sistema de curtidas e comentários
- Busca por destino ou categoria
- Importação para biblioteca pessoal
- Fotos e avaliações detalhadas
- Notificações de interações

### 7. Recursos de Segurança

**Proteção e Tranquilidade Durante a Viagem**

- **Botão de Pânico**: Envio automático de SMS e WhatsApp para contatos de emergência
- **Check-ins de Segurança**: Lembretes periódicos com compartilhamento de localização
- **Histórico de Segurança**: Registro de todos os check-ins realizados
- **Contatos de Emergência**: Configuração de contatos para situações críticas
- **Compartilhamento de Localização**: Tempo real com membros do grupo

### 8. Previsão do Tempo

**Informações Meteorológicas Detalhadas (OpenWeatherMap API)**

- Clima atual com temperatura, umidade e vento
- Previsão de 5 dias
- Probabilidade de chuva
- Horário do nascer e pôr do sol
- Alertas meteorológicos
- Índice UV
- Ícones animados de clima

### 9. Informações de Destino

**Dados Completos sobre o País (REST Countries API)**

- Nome oficial e comum
- Capital e população
- Moeda oficial e símbolo
- Idiomas falados
- Fuso horário
- Código de discagem internacional
- Bandeira do país

### 10. Recursos Adicionais

- **Modo Escuro**: Interface adaptável para diferentes condições de luz
- **Acessibilidade**: Suporte a leitores de tela e navegação por teclado
- **Notificações Inteligentes**: Lembretes contextuais baseados em atividades
- **Cache Offline**: Funcionamento sem conexão com sincronização automática
- **Otimização de Memória**: Gerenciamento inteligente para dispositivos antigos
- **Múltiplos Idiomas**: Suporte a português (pt-BR)

---

## Tecnologias

### Frontend

**Flutter 3.5.0**
- Framework multiplataforma da Google
- Hot reload para desenvolvimento rápido
- Widgets nativos para cada plataforma
- Performance próxima ao nativo

**Dart 3.0**
- Linguagem moderna e type-safe
- Null safety
- Async/await para operações assíncronas
- Strong typing

**Material Design 3**
- Design system moderno
- Componentes acessíveis
- Temas claro e escuro
- Animações fluidas

### Backend

**Firebase Authentication**
- Autenticação segura de usuários
- Suporte a email/senha
- Recuperação de senha
- Gerenciamento de sessões

**Cloud Firestore**
- Banco de dados NoSQL em tempo real
- Sincronização automática
- Queries complexas
- Offline persistence

**Firebase Storage**
- Armazenamento de imagens
- Upload/download otimizado
- Compressão automática
- URLs seguros

**Firebase Cloud Messaging**
- Push notifications
- Notificações em background
- Segmentação de usuários
- Analytics integrado

### APIs Externas

**Geoapify**
- Sugestões de locais (POIs)
- Geocoding e reverse geocoding
- Cálculo de rotas
- 3.000 requisições/dia gratuitas

**OpenWeatherMap**
- Previsão do tempo
- Clima atual e forecast de 5 dias
- Alertas meteorológicos
- 1.000 requisições/dia gratuitas

**REST Countries**
- Informações de países
- Completamente gratuito
- Sem limite de requisições
- Dados atualizados

**ExchangeRate API**
- Conversão de moedas
- Taxas em tempo real
- 161 moedas suportadas
- 1.500 requisições/mês gratuitas

**Nominatim (OpenStreetMap)**
- Geocoding gratuito
- Busca de endereços
- Reverse geocoding
- Dados do OpenStreetMap

### Bibliotecas Principais

```yaml
dependencies:
  # Firebase
  firebase_core: ^4.6.0
  firebase_auth: ^6.3.0
  cloud_firestore: ^6.2.0
  firebase_storage: ^13.2.0
  firebase_messaging: ^16.1.3
  
  # UI e Navegação
  provider: ^6.1.2
  intl: ^0.20.2
  
  # Funcionalidades
  image_picker: ^1.1.2
  share_plus: ^10.0.0
  url_launcher: ^6.3.1
  geolocator: ^13.0.2
  
  # Notificações
  flutter_local_notifications: ^21.0.0
  timezone: ^0.11.0
  
  # Cache e Performance
  shared_preferences: ^2.3.3
  connectivity_plus: ^7.1.1
  cached_network_image: ^3.4.1
  
  # Exportação
  pdf: ^3.11.1
  path_provider: ^2.1.5
  screenshot: ^3.0.0
  
  # HTTP
  http: ^1.1.0
```

---

## Arquitetura

### Padrão Arquitetural

O projeto utiliza o padrão **MVC (Model-View-Controller)** adaptado para Flutter:


### Camadas

**1. Presentation (Screens)**
- Interface do usuário
- Widgets Flutter
- Interação com o usuário
- Navegação entre telas

**2. Business Logic (Controllers)**
- Lógica de aplicação
- Gerenciamento de estado (Provider)
- Validações de negócio
- Orquestração de serviços

**3. Data (Models + Services)**
- **Models**: Estrutura de dados e serialização
- **Services**: Integração com Firebase e APIs externas
- Cache e persistência local
- Tratamento de erros


### Gerenciamento de Estado

**Provider Pattern**
```dart
ChangeNotifierProvider(
  create: (_) => ThemeController(),
  child: Consumer<ThemeController>(
    builder: (context, controller, _) {
      return MaterialApp(
        themeMode: controller.themeMode,
        // ...
      );
    },
  ),
)
```

### Segurança

**Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários só podem ler/escrever seus próprios dados
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Viagens: acesso apenas para membros
    match /trips/{tripId} {
      allow read: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         request.auth.uid in resource.data.members);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }
  }
}
```

---

## Início Rápido

### Pré-requisitos

```bash
# Verificar instalação do Flutter
flutter doctor -v

# Versões necessárias
Flutter SDK: 3.5.0+
Dart SDK: 3.0.0+
```

### Instalação

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd TCC

# 2. Instalar dependências
flutter pub get

# 3. Configurar API Keys (opcional para desenvolvimento)
cp lib/config/api_keys.dart.example lib/config/api_keys.dart
# Edite api_keys.dart com suas chaves

# 4. Executar o aplicativo
flutter run
```

### Executar em Diferentes Plataformas

```bash
# Android
flutter run -d android

# iOS (apenas macOS)
flutter run -d ios

# Web
flutter run -d chrome

# Desktop
flutter run -d windows  # ou macos, linux
```

### Build para Produção

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release  # ou macos, linux
```

Para guia completo de execução, consulte: [Como Executar no Emulador](docs/desenvolvimento/COMO_EXECUTAR_NO_EMULADOR.md)

---

## Estrutura do Projeto

```
TCC/
├── android/                    # Configurações Android
├── ios/                        # Configurações iOS
├── web/                        # Configurações Web
├── windows/                    # Configurações Windows
├── macos/                      # Configurações macOS
├── linux/                      # Configurações Linux
│
├── docs/                       # DOCUMENTAÇÃO COMPLETA
│   ├── README.md               # Índice de navegação
│   ├── ORGANIZACAO_PROJETO.md  # Documentação da organização
│   ├── desenvolvimento/        # Guias técnicos (3 docs)
│   ├── apis/                   # Documentação de APIs (4 docs)
│   ├── planejamento/           # Roadmap e melhorias (5 docs)
│   └── assets/                 # Design e imagens
│
├── lib/                        # CÓDIGO FONTE
│   ├── config/                 # Configurações
│   │   └── api_keys.dart.example
│   │
│   ├── controllers/            # Lógica de negócio
│   │   ├── auth_controller.dart
│   │   ├── trip_controller.dart
│   │   ├── theme_controller.dart
│   │   └── packing_checklist_controller.dart
│   │
│   ├── data/                   # Dados estáticos
│   │   ├── activity_data.dart
│   │   ├── expense_data.dart
│   │   ├── packing_templates.dart
│   │   └── trip_data.dart
│   │
│   ├── models/                 # Modelos de dados
│   │   ├── trip.dart
│   │   ├── expense.dart
│   │   ├── activity.dart
│   │   ├── journal_entry.dart
│   │   ├── service_model.dart
│   │   ├── user_model.dart
│   │   ├── safety_checkin.dart
│   │   ├── destination_rating.dart
│   │   ├── notification_model.dart
│   │   └── user_subscription.dart
│   │
│   ├── screens/                # Telas do aplicativo (30+ telas)
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── trips_page.dart
│   │   ├── trip_dashboard_page.dart
│   │   ├── create_trip_page.dart
│   │   ├── itinerary_page.dart
│   │   ├── create_activity_page.dart
│   │   ├── activity_suggestions_page.dart
│   │   ├── expenses_page.dart
│   │   ├── create_expense_page.dart
│   │   ├── reports_page.dart
│   │   ├── journal_page.dart
│   │   ├── create_journal_entry_page.dart
│   │   ├── photo_gallery_page.dart
│   │   ├── services_library_page.dart
│   │   ├── community_page.dart
│   │   ├── add_recommendation_page.dart
│   │   ├── safety_page.dart
│   │   ├── insights_page.dart
│   │   ├── profile_page.dart
│   │   ├── packing_checklist_page.dart
│   │   ├── select_packing_template_page.dart
│   │   ├── group_members_page.dart
│   │   ├── rate_destination_page.dart
│   │   ├── smart_suggestions_page.dart
│   │   ├── flight_search_page.dart
│   │   ├── hotel_search_page.dart
│   │   ├── premium_upgrade_page.dart
│   │   ├── welcome_premium_page.dart
│   │   ├── business_panel_page.dart
│   │   └── onboarding_page.dart
│   │
│   ├── services/               # Serviços e integrações
│   │   ├── auth_service.dart
│   │   ├── trip_service.dart
│   │   ├── storage_service.dart
│   │   ├── notification_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── smart_notification_service.dart
│   │   ├── cache_service.dart
│   │   ├── memory_manager_service.dart
│   │   ├── analytics_service.dart
│   │   ├── subscription_service.dart
│   │   ├── packing_checklist_service.dart
│   │   ├── social_share_service.dart
│   │   ├── pdf_export_service.dart
│   │   ├── geoapify_service.dart
│   │   ├── openweathermap_service.dart
│   │   ├── rest_countries_service.dart
│   │   ├── exchangerate_service.dart
│   │   ├── external_apps_service.dart
│   │   └── http_client_service.dart
│   │
│   ├── theme/                  # Temas e estilos
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   │
│   ├── widgets/                # Componentes reutilizáveis
│   │   ├── accessible_button.dart
│   │   ├── accessible_card.dart
│   │   ├── optimized_image.dart
│   │   ├── theme_toggle_button.dart
│   │   └── charts/
│   │       ├── gauge_chart_widget.dart
│   │       ├── heatmap_widget.dart
│   │       ├── line_chart_widget.dart
│   │       └── waterfall_chart_widget.dart
│   │
│   ├── firebase_options.dart   # Configuração Firebase
│   └── main.dart               # Ponto de entrada
│
├── test/                       # Testes automatizados
│   ├── widget_test.dart
│   ├── use_cases_test.dart
│   ├── trip_model_test.dart
│   ├── security_test.dart
│   ├── security_logic_test.dart
│   ├── security_functional_test.dart
│   ├── profile_validation_test.dart
│   ├── auth_validation_test.dart
│   ├── accessibility_test.dart
│   ├── notifications_test.dart
│   └── apis_integration_test.dart
│
├── assets/                     # Assets do aplicativo
│   └── images/
│       ├── app_logo.png
│       ├── icone_aviao.png
│       ├── icone_perfil.png
│       ├── imagi03.jpg
│       ├── imagi04.jpg
│       └── imagi05.jpg
│
├── .gitignore                  # Arquivos ignorados pelo Git
├── pubspec.yaml                # Dependências do projeto
├── firebase.json               # Configuração Firebase Hosting
├── firestore.rules             # Regras de segurança Firestore
├── firestore.indexes.json      # Índices do Firestore
└── README.md                   # Este arquivo
```

### Destaques da Organização

- **Documentação Centralizada**: Toda documentação em `docs/`
- **Código Organizado**: Separação clara de responsabilidades (MVC)
- **30+ Telas**: Interface completa e intuitiva
- **20+ Serviços**: Integrações robustas
- **10+ Testes**: Cobertura de funcionalidades críticas
- **Assets Separados**: Design e documentação organizados
- **Configurações Isoladas**: API keys em arquivo separado

---

## Documentação

### Documentação Completa

Acesse o [Índice de Documentação](docs/README.md) para navegação completa.

### Guias de Desenvolvimento

- [Como Executar no Emulador](docs/desenvolvimento/COMO_EXECUTAR_NO_EMULADOR.md) - Guia completo de setup e execução
- [Configuração do Firebase](docs/desenvolvimento/CONFIGURACAO_FIREBASE_HOSTING.md) - Deploy e configuração
- [Guia de Contribuição](docs/desenvolvimento/CONTRIBUTING.md) - Como contribuir com o projeto

### Documentação de APIs

- [APIs Gratuitas Integradas](docs/apis/APIS_GRATUITAS_ROTEIRO_INTELIGENTE.md) - Visão geral das APIs
- [Implementação das APIs](docs/apis/IMPLEMENTACAO_APIS_FINAL.md) - Detalhes técnicos
- [Comparação Google Maps vs Alternativas](docs/apis/COMPARACAO_GOOGLE_MAPS_VS_ALTERNATIVAS.md) - Análise
- [Alternativa OpenTripMap](docs/apis/ALTERNATIVA_OPENTRIPMAP.md) - API complementar

### Planejamento e Roadmap

- [Novas Funcionalidades](docs/planejamento/NOVAS_FUNCIONALIDADES.md) - Features implementadas
- [Plano de Melhorias](docs/planejamento/PLANO_MELHORIAS_FUNCIONALIDADES.md) - Roadmap futuro
- [Melhorias de Segurança](docs/planejamento/MELHORIAS_SEGURANCA.md) - Recursos de segurança
- [Melhorias do Journal](docs/planejamento/MELHORIAS_JOURNAL_PLANEJADAS.md) - Evolução do diário
- [Guia de Compartilhamento](docs/planejamento/GUIA_COMPARTILHAMENTO_JOURNAL.md) - Como usar

### Design e Assets

- [Documentação de Design](docs/assets/AppTravel.pdf) - Guia visual completo
- [Estrutura do Banco](docs/planejamento/banco.json) - Schema do Firestore

---

## Testes

### Executar Testes

```bash
# Todos os testes
flutter test

# Teste específico
flutter test test/use_cases_test.dart

# Com cobertura
flutter test --coverage

# Gerar relatório HTML
genhtml coverage/lcov.info -o coverage/html
```

### Cobertura de Testes

O projeto inclui testes abrangentes para:

**1. Modelos de Dados**
- Validação de campos obrigatórios
- Serialização/deserialização JSON
- Regras de negócio

**2. Lógica Financeira**
- Algoritmo de divisão de despesas
- Conversão de moedas
- Cálculo de balanços

**3. Segurança**
- Validação de permissões
- Regras de acesso a dados
- Autenticação e autorização
- Testes funcionais de segurança

**4. Casos de Uso**
- Fluxos completos de funcionalidades
- Integração entre componentes
- Validação de estados

**5. Acessibilidade**
- Suporte a leitores de tela
- Navegação por teclado
- Contraste de cores

**6. Integrações**
- APIs externas
- Firebase services
- Notificações

### Exemplo de Teste

```dart
void main() {
  group('Trip Model Tests', () {
    test('deve criar viagem válida', () {
      final trip = Trip(
        id: '123',
        ownerId: 'user1',
        destination: 'Paris',
        budget: 5000.0,
        objective: 'Lazer',
        createdAt: DateTime.now(),
      );
      
      expect(trip.destination, 'Paris');
      expect(trip.budget, 5000.0);
      expect(trip.isAdmin('user1'), true);
    });
  });
}
```


### Convenção de Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Apenas documentação
- `test`: Adicionar testes
- `chore`: Manutenção

### Guia Completo

Leia o [Guia de Contribuição](docs/desenvolvimento/CONTRIBUTING.md) para detalhes sobre:
- Código de conduta
- Processo de desenvolvimento
- Style guide
- Testes
- Code review

---

## Licença

Este projeto foi desenvolvido como **Trabalho de Conclusão de Curso (TCC)** para fins acadêmicos.

**Instituição:** ETEC  
**Curso:** Desenvolvimento de Sistemas  
**Ano:** 2026

---

## Reconhecimentos

- **Orientadores** - Pela orientação e suporte durante o desenvolvimento
- **ETEC** - Pela infraestrutura e ensino de qualidade
- **Comunidade Flutter** - Pelas bibliotecas e recursos disponibilizados
- **APIs Gratuitas** - Por possibilitar as integrações sem custo
- **Firebase** - Pela plataforma robusta e gratuita para desenvolvimento

---


## Estatísticas do Projeto

- **Linhas de Código**: ~15.000+
- **Telas**: 30+
- **Modelos**: 12
- **Serviços**: 20+
- **Testes**: 10+
- **Documentação**: 17 arquivos
- **APIs Integradas**: 5
- **Plataformas Suportadas**: 6 (Android, iOS, Web, Windows, macOS, Linux)

---

<div align="center">

**Desenvolvido com Flutter**

[Voltar ao topo](#travel-app---sistema-de-planejamento-e-gestão-de-viagens)

</div>
