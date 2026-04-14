# Travel App - Sistema Inteligente de Planejamento e Gestão de Viagens

## Sobre o Projeto

Este é um Trabalho de Conclusão de Curso (TCC) que apresenta uma solução completa para planejamento e gestão de viagens individuais e em grupo. O Travel App foi desenvolvido com Flutter e Firebase, oferecendo uma plataforma robusta que combina organização logística, controle financeiro compartilhado e documentação colaborativa de experiências de viagem.

## Finalidade do Aplicativo

O Travel App foi criado para resolver os principais desafios enfrentados por viajantes modernos:

### Problemas que o App Resolve

1. **Desorganização no Planejamento**
   - Centraliza todas as informações da viagem em um único lugar
   - Permite criar itinerários detalhados com atividades, horários e localizações
   - Suporta viagens planejadas e viagens nômades (sem data de término definida)

2. **Conflitos em Viagens em Grupo**
   - Sistema de votação democrática para aprovação de atividades
   - Gestão de membros com controle de permissões (administrador e membros)
   - Código de convite único para entrada no grupo

3. **Dificuldade na Divisão de Gastos**
   - Registro categorizado de todas as despesas da viagem
   - Algoritmo automático de divisão de custos entre membros
   - Relatório em tempo real de "quem deve para quem"
   - Suporte a múltiplas moedas com conversão automática
   - Função de cobrança via WhatsApp integrada

4. **Perda de Memórias e Experiências**
   - Diário de bordo digital com fotos e análise de humor (mood tracking)
   - Álbum de viagem compartilhável via link público
   - Registro de localização em cada entrada do diário

5. **Falta de Recomendações Confiáveis**
   - Biblioteca pessoal de serviços (hospedagem, restaurantes, transporte)
   - Comunidade para compartilhar e descobrir recomendações de outros viajantes
   - Sistema de avaliações com fotos e custos médios

6. **Preocupação com Segurança**
   - Botão de pânico que envia SMS e WhatsApp automáticos para contato de emergência
   - Check-ins de segurança com histórico
   - Compartilhamento de localização em tempo real

## Funcionalidades Principais

### Gestão de Viagens
- Criação de viagens individuais ou em grupo
- Planejamento com datas definidas ou modo nômade
- Controle de orçamento e gastos
- Status da viagem (planejada, ativa, finalizada)

### Itinerário e Atividades
- Cronograma detalhado de atividades
- Organização por data, horário e categoria
- Sistema de votação para atividades em grupo
- Integração com busca de voos

### Finanças
- Registro de despesas por categoria
- Divisão automática de custos
- Conversão de moedas em tempo real
- Relatórios de balanço do grupo
- Compartilhamento de cobranças

### Diário de Viagem
- Registro de memórias com fotos
- Análise de humor (mood tracking)
- Localização de cada entrada
- Álbum compartilhável publicamente
- Busca por localização

### Comunidade
- Feed público de recomendações
- Importação para biblioteca pessoal
- Avaliações com fotos e custos
- Busca por nome, local ou categoria

### Segurança
- Botão de pânico com envio automático de SMS e WhatsApp
- Check-ins de segurança
- Histórico de registros
- Configuração de contato de emergência

## Especificações Técnicas

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
- **Arquitetura:** Controller Pattern
- **Plataformas:** Android, iOS, Web, Windows, macOS, Linux
- **Principais Dependências:**
  - firebase_core, firebase_auth, cloud_firestore
  - image_picker, share_plus
  - intl (internacionalização)
  - url_launcher (integração com SMS/WhatsApp)
  - http (conversão de moedas)

## Como Executar o Projeto

### Pré-requisitos

Antes de começar, certifique-se de ter instalado:
- Flutter SDK (versão 3.11.1 ou superior)
- Dart (incluído no Flutter)
- Git

Para desenvolvimento em plataformas específicas:
- **Android:** Android Studio com Android SDK
- **iOS/macOS:** Xcode (apenas em macOS)
- **Web:** Google Chrome
- **Windows:** Visual Studio 2022 com desenvolvimento para desktop C++

### Passos para Instalação

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd TCC
```

2. Instale as dependências do Flutter:
```bash
flutter pub get
```

3. Execute o aplicativo:

**Para Android (com dispositivo conectado ou emulador):**
```bash
flutter run
```

**Para iOS (apenas em macOS):**
```bash
flutter run -d ios
```

**Para Web:**
```bash
flutter run -d chrome
```

**Para Windows:**
```bash
flutter run -d windows
```

**Para macOS:**
```bash
flutter run -d macos
```

**Para Linux:**
```bash
flutter run -d linux
```

### Executar Testes

Para validar a integridade do sistema:
```bash
flutter test
```

Os testes cobrem:
- Modelos de dados e validações
- Lógica financeira e divisão de despesas
- Regras de negócio e permissões
- Integração entre componentes

## Observações Importantes

- O Firebase já está configurado no projeto com credenciais para todas as plataformas
- Não é necessário configurar o Firebase manualmente
- O comando `flutter pub get` é obrigatório após clonar o repositório
- Para desenvolvimento, recomenda-se usar um IDE como VS Code ou Android Studio
- O projeto suporta hot reload para desenvolvimento mais rápido

## Estrutura do Projeto

```
lib/
├── controllers/      # Lógica de negócio e gerenciamento de estado
├── data/            # Dados mockados para desenvolvimento
├── models/          # Modelos de dados
├── screens/         # Telas do aplicativo
├── services/        # Serviços (Firebase, API, notificações)
├── firebase_options.dart  # Configurações do Firebase
└── main.dart        # Ponto de entrada do aplicativo
```

## Licença

Este é um projeto acadêmico desenvolvido como Trabalho de Conclusão de Curso (TCC).
