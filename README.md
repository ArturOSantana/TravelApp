# Travel App - Sistema de Planejamento e Gestão de Viagens

## Trabalho de Conclusão de Curso

**Instituição:** ETEC  
**Curso:** Desenvolvimento de Sistemas  
**Versão:** 1.0.0

---

## Sumário

1. [Visão Geral](#visão-geral)
2. [Justificativa](#justificativa)
3. [Objetivos](#objetivos)
4. [Funcionalidades](#funcionalidades)
5. [Arquitetura e Tecnologias](#arquitetura-e-tecnologias)
6. [Requisitos do Sistema](#requisitos-do-sistema)
7. [Instalação e Execução](#instalação-e-execução)
8. [Estrutura do Projeto](#estrutura-do-projeto)
9. [Testes](#testes)
10. [Considerações Finais](#considerações-finais)

---

## Visão Geral

O Travel App é uma aplicação multiplataforma desenvolvida para solucionar problemas comuns no planejamento e gestão de viagens, tanto individuais quanto em grupo. O sistema oferece ferramentas integradas para organização de itinerários, controle financeiro compartilhado, documentação de experiências e recursos de segurança.

### Problema Identificado

Viajantes enfrentam dificuldades na coordenação de grupos, divisão de despesas, organização de informações e preservação de memórias. Aplicativos existentes geralmente focam em aspectos isolados, exigindo o uso de múltiplas ferramentas desconectadas.

### Solução Proposta

Uma plataforma unificada que integra planejamento, gestão financeira, documentação colaborativa e recursos de segurança, com sincronização em tempo real e suporte offline.

---

## Justificativa

### Contexto de Mercado

O setor de turismo movimenta bilhões anualmente, com crescente demanda por ferramentas digitais que facilitem a experiência do viajante. A pandemia acelerou a digitalização do setor, criando oportunidades para soluções inovadoras.

### Diferencial Competitivo

- **Integração completa:** Todas as funcionalidades essenciais em um único aplicativo
- **Colaboração em tempo real:** Sincronização instantânea entre membros do grupo
- **Gestão financeira avançada:** Algoritmo automático de divisão de despesas
- **Segurança:** Recursos de emergência e check-ins de segurança
- **Multiplataforma:** Disponível para Android, iOS, Web e Desktop

---

## Objetivos

### Objetivo Geral

Desenvolver um sistema multiplataforma para planejamento e gestão de viagens que integre organização logística, controle financeiro e documentação de experiências.

### Objetivos Específicos

1. Implementar sistema de autenticação e gerenciamento de usuários
2. Criar módulo de planejamento de viagens com suporte a grupos
3. Desenvolver sistema de controle financeiro com divisão automática de despesas
4. Implementar diário de viagem digital com compartilhamento público
5. Criar biblioteca de serviços e comunidade de recomendações
6. Integrar recursos de segurança e emergência
7. Garantir funcionamento offline com sincronização automática

---

## Funcionalidades

### 1. Gestão de Viagens

**Descrição:** Módulo central para criação e gerenciamento de viagens.

**Recursos:**
- Criação de viagens individuais ou em grupo (até 20 membros)
- Suporte a viagens planejadas (com datas) ou nômades (sem data de término)
- Definição de orçamento e acompanhamento de gastos
- Sistema de convite por código único
- Controle de permissões (administrador e membros)
- Status da viagem (planejada, ativa, concluída)

### 2. Itinerário e Atividades

**Descrição:** Organização cronológica de atividades da viagem.

**Recursos:**
- Criação de atividades com data, horário e localização
- Categorização (transporte, hospedagem, alimentação, passeio, etc.)
- Sistema de votação democrática para aprovação em grupos
- Integração com busca de voos e hotéis
- Visualização em lista ordenada por data
- Notificações de atividades próximas

### 3. Controle Financeiro

**Descrição:** Gestão completa de despesas e divisão de custos.

**Recursos:**
- Registro de despesas por categoria
- Algoritmo automático de divisão entre membros
- Suporte a múltiplas moedas com conversão em tempo real
- Relatório de balanço ("quem deve para quem")
- Exportação de relatórios em PDF
- Compartilhamento de cobranças via WhatsApp
- Gráficos de distribuição de gastos

### 4. Diário de Viagem

**Descrição:** Documentação digital de experiências e memórias.

**Recursos:**
- Criação de entradas com texto, fotos e localização
- Análise de humor (mood tracking)
- Galeria de fotos organizada por viagem
- Álbum público compartilhável via link
- Busca por localização
- Reações e comentários de membros do grupo
- Exportação de entradas

### 5. Biblioteca de Serviços

**Descrição:** Catálogo pessoal de estabelecimentos e serviços.

**Recursos:**
- Registro de hospedagens, restaurantes, transportes e atrações
- Avaliação com estrelas e fotos
- Informações de custo médio e localização
- Categorização e busca
- Importação de recomendações da comunidade

### 6. Comunidade

**Descrição:** Rede social para compartilhamento de recomendações.

**Recursos:**
- Feed público de recomendações
- Sistema de curtidas e comentários
- Busca por destino ou categoria
- Importação para biblioteca pessoal
- Fotos e avaliações detalhadas

### 7. Segurança

**Descrição:** Recursos para garantir a segurança do viajante.

**Recursos:**
- Botão de pânico com envio automático de SMS e WhatsApp
- Check-ins de segurança com localização
- Histórico de registros de segurança
- Configuração de contato de emergência
- Compartilhamento de localização em tempo real

### 8. Recursos Adicionais

- **Modo escuro:** Interface adaptável para diferentes condições de luz
- **Acessibilidade:** Suporte a leitores de tela e navegação por teclado
- **Notificações inteligentes:** Lembretes contextuais baseados em atividades
- **Cache offline:** Funcionamento sem conexão com sincronização automática
- **Busca de voos e hotéis:** Integração com APIs de busca

---

## Arquitetura e Tecnologias

### Stack Tecnológico

**Frontend:**
- Flutter 3.5.0 (Framework multiplataforma)
- Dart (Linguagem de programação)
- Material Design 3 (Design system)

**Backend:**
- Firebase Authentication (Autenticação de usuários)
- Cloud Firestore (Banco de dados NoSQL em tempo real)
- Firebase Storage (Armazenamento de imagens)
- Firebase Cloud Messaging (Notificações push)

**APIs Externas:**
- API de conversão de moedas
- Geolocator (Serviços de localização)
- URL Launcher (Integração com SMS/WhatsApp)

### Padrão Arquitetural

O projeto utiliza o padrão **Controller**, separando responsabilidades em:

- **Models:** Representação de dados e regras de negócio
- **Controllers:** Lógica de aplicação e gerenciamento de estado
- **Services:** Integração com APIs e serviços externos
- **Screens:** Interface do usuário e interação

### Principais Dependências

```yaml
dependencies:
  firebase_core: ^4.6.0
  firebase_auth: ^6.3.0
  cloud_firestore: ^6.2.0
  firebase_storage: ^13.2.0
  firebase_messaging: ^16.1.3
  image_picker: ^1.1.2
  share_plus: ^10.0.0
  geolocator: ^13.0.2
  url_launcher: ^6.3.1
  intl: ^0.20.2
  provider: ^6.1.2
  shared_preferences: ^2.3.3
  connectivity_plus: ^7.1.1
  pdf: ^3.11.1
```

---

## Requisitos do Sistema

### Requisitos de Hardware

**Mínimo:**
- Processador: Dual-core 1.5 GHz
- RAM: 2 GB
- Armazenamento: 500 MB livres
- Conexão com internet (para sincronização)

**Recomendado:**
- Processador: Quad-core 2.0 GHz ou superior
- RAM: 4 GB ou superior
- Armazenamento: 1 GB livres
- Conexão 4G/Wi-Fi estável

### Requisitos de Software

**Para Desenvolvimento:**
- Flutter SDK 3.5.0 ou superior
- Dart SDK (incluído no Flutter)
- Git 2.0 ou superior

**Plataformas Específicas:**
- **Android:** Android Studio com Android SDK (API 21+)
- **iOS:** Xcode 14+ (apenas macOS)
- **Web:** Navegador moderno (Chrome, Firefox, Safari, Edge)
- **Windows:** Visual Studio 2022 com C++ Desktop Development
- **macOS:** Xcode Command Line Tools
- **Linux:** Dependências GTK 3.0

---

## Instalação e Execução

### 1. Preparação do Ambiente

#### Instalar Flutter

**Windows/macOS/Linux:**
```bash
# Baixar Flutter SDK de https://flutter.dev/docs/get-started/install
# Adicionar Flutter ao PATH do sistema
flutter doctor
```

#### Verificar Instalação

```bash
flutter doctor -v
```

Este comando verifica todas as dependências necessárias.

### 2. Clonar o Repositório

```bash
git clone <url-do-repositorio>
cd TCC
```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Executar o Aplicativo

#### Android

**Com dispositivo físico:**
1. Ativar modo desenvolvedor no dispositivo
2. Conectar via USB
3. Executar:

```bash
flutter run
```

**Com emulador:**
1. Criar AVD no Android Studio
2. Iniciar emulador
3. Executar:

```bash
flutter run
```

#### iOS (apenas macOS)

```bash
cd ios
pod install
cd ..
flutter run -d ios
```

#### Web

```bash
flutter run -d chrome
```

#### Desktop

**Windows:**
```bash
flutter run -d windows
```

**macOS:**
```bash
flutter run -d macos
```

**Linux:**
```bash
flutter run -d linux
```

### 5. Build para Produção

#### Android (APK)

```bash
flutter build apk --release
```

O arquivo será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

#### Android (App Bundle)

```bash
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

#### Web

```bash
flutter build web --release
```

Os arquivos serão gerados em: `build/web/`

---

## Estrutura do Projeto

```
travel_app/
│
├── android/                 # Configurações Android
├── ios/                     # Configurações iOS
├── web/                     # Configurações Web
├── windows/                 # Configurações Windows
├── macos/                   # Configurações macOS
├── linux/                   # Configurações Linux
│
├── lib/
│   ├── controllers/         # Lógica de negócio
│   │   ├── auth_controller.dart
│   │   ├── trip_controller.dart
│   │   ├── theme_controller.dart
│   │   └── packing_checklist_controller.dart
│   │
│   ├── models/              # Modelos de dados
│   │   ├── trip.dart
│   │   ├── expense.dart
│   │   ├── activity.dart
│   │   ├── journal_entry.dart
│   │   ├── service_model.dart
│   │   ├── user_model.dart
│   │   ├── safety_checkin.dart
│   │   └── destination_rating.dart
│   │
│   ├── screens/             # Telas do aplicativo
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── trips_page.dart
│   │   ├── trip_dashboard_page.dart
│   │   ├── create_trip_page.dart
│   │   ├── itinerary_page.dart
│   │   ├── expenses_page.dart
│   │   ├── journal_page.dart
│   │   ├── community_page.dart
│   │   ├── safety_page.dart
│   │   ├── insights_page.dart
│   │   └── profile_page.dart
│   │
│   ├── services/            # Serviços externos
│   │   ├── auth_service.dart
│   │   ├── trip_service.dart
│   │   ├── notification_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── cache_service.dart
│   │   ├── currency_service.dart
│   │   ├── location_service.dart
│   │   ├── storage_service.dart
│   │   └── pdf_export_service.dart
│   │
│   ├── theme/               # Temas e estilos
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   │
│   ├── widgets/             # Componentes reutilizáveis
│   │   ├── accessible_button.dart
│   │   ├── accessible_card.dart
│   │   └── theme_toggle_button.dart
│   │
│   ├── firebase_options.dart
│   └── main.dart            # Ponto de entrada
│
├── test/                    # Testes automatizados
│   ├── widget_test.dart
│   ├── use_cases_test.dart
│   ├── security_test.dart
│   └── profile_validation_test.dart
│
├── assets/                  # Recursos estáticos
│   └── images/
│
├── pubspec.yaml             # Dependências do projeto
├── firebase.json            # Configuração Firebase
├── firestore.rules          # Regras de segurança Firestore
└── README.md
```

---

## Testes

### Executar Todos os Testes

```bash
flutter test
```

### Executar Teste Específico

```bash
flutter test test/use_cases_test.dart
```

### Cobertura de Testes

O projeto inclui testes para:

1. **Modelos de Dados**
   - Validação de campos obrigatórios
   - Serialização/deserialização JSON
   - Regras de negócio

2. **Lógica Financeira**
   - Algoritmo de divisão de despesas
   - Conversão de moedas
   - Cálculo de balanços

3. **Segurança**
   - Validação de permissões
   - Regras de acesso a dados
   - Autenticação e autorização

4. **Casos de Uso**
   - Fluxos completos de funcionalidades
   - Integração entre componentes
   - Validação de estados

### Relatório de Cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Considerações Finais

### Resultados Alcançados

O Travel App atende aos objetivos propostos, oferecendo uma solução completa e integrada para planejamento e gestão de viagens. A aplicação demonstra:

- Domínio de desenvolvimento multiplataforma com Flutter
- Integração eficiente com serviços Firebase
- Implementação de padrões de arquitetura escaláveis
- Preocupação com experiência do usuário e acessibilidade
- Aplicação de boas práticas de desenvolvimento

### Trabalhos Futuros

Possíveis melhorias e expansões:

1. Integração com mais APIs de serviços de viagem
2. Implementação de inteligência artificial para recomendações personalizadas
3. Sistema de gamificação para engajamento
4. Suporte a mais idiomas
5. Integração com assistentes virtuais
6. Modo offline completo com sincronização otimizada

### Limitações Conhecidas

- Dependência de conexão para algumas funcionalidades
- Limite de 20 membros por grupo na versão gratuita
- Conversão de moedas depende de API externa

---

## Licença

Este projeto foi desenvolvido como Trabalho de Conclusão de Curso (TCC) para fins acadêmicos.

**Instituição:** ETEC  
**Ano:** 2026

---

## Contato

Para dúvidas ou sugestões sobre o projeto, entre em contato através do repositório.
