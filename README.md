# Travel App - Planejamento Inteligente de Viagens 🌍✈️

O **Travel App** é uma solução completa para viajantes que buscam organizar suas jornadas de forma inteligente, seja em aventuras solo ou em grupo. O foco principal é a praticidade, controle financeiro e a criação de uma memória de viagem rica e colaborativa.

---

## 🚀 Funcionalidades Principais (Casos de Uso)

### 1. Gerenciamento de Viagens
- **Viagem Solo:** Criação rápida com definição de destino, orçamento e objetivo (lazer, trabalho, etc).
- **Modo Nômade:** Suporte para viagens sem data de término definida.
- **Viagens em Grupo:** Sistema de convite via código privado com gestão de permissões (ADM e Membros).

### 2. Roteiro Inteligente 📅
- **Organização por Dias:** Adicione atividades com horários e localizações.
- **Votação em Grupo:** Evite conflitos permitindo que os membros votem (aprovar/reprovar) em atividades propostas.

### 3. Controle Financeiro 💰
- **Gestão de Gastos:** Registro individual categorizado (alimentação, transporte, etc).
- **Divisão Automática:** Em viagens de grupo, o sistema calcula "quem deve para quem" com base em divisões personalizadas.

### 4. Biblioteca de Recomendações & Comunidade 🌟
- **Memória Pessoal:** Salve serviços (hotéis, restaurantes) com fotos, avaliações e dicas.
- **Feed da Comunidade:** Explore e salve dicas de outros usuários para suas próprias viagens.
- **Privacidade:** Escolha se sua recomendação será pública ou apenas para você.

### 5. Diário de Viagem & Segurança 📖🛟
- **Diário Emocional:** Registre fotos e textos com escala de humor diária.
- **Check-in de Segurança:** Compartilhamento de localização e botão "Estou Seguro" para tranquilizar familiares.

---

## 🧪 Como rodar os Testes

O projeto utiliza **Testes Unitários** para garantir que todas as regras de negócio (Casos de Uso) funcionem corretamente.

### Pré-requisitos
Certifique-se de que o Flutter está configurado corretamente em sua máquina:
```bash
flutter doctor
```

### Executando os Testes
Para rodar todos os testes de lógica de negócio:

1. **Testes de Casos de Uso (Geral):**
   Valida criação de viagens, votação de atividades, divisão financeira e diário.
   ```bash
   flutter test test/use_cases_test.dart
   ```

2. **Testes de Lógica de Permissão (ADM/Membro):**
   Garante que apenas o administrador tenha poderes de edição e exclusão.
   ```bash
   flutter test test/trip_model_test.dart
   ```

3. **Rodar todos os testes do projeto:**
   ```bash
   flutter test
   ```

---

## 🛠 Tecnologias Utilizadas
- **Flutter** (Framework UI)
- **Firebase Auth** (Autenticação)
- **Cloud Firestore** (Banco de dados em tempo real)
- **Provider/Controller Pattern** (Gestão de estado e lógica)
