# Travel App - Sistema Inteligente de Planejamento e Gestão de Viagens

## Visão Geral
O Travel App é uma plataforma robusta desenvolvida para otimizar a experiência de planejamento e execução de viagens individuais e coletivas. O sistema foca em três pilares fundamentais: organização logística, controle financeiro compartilhado e documentação colaborativa de experiências.

Este projeto foi estruturado seguindo padrões de arquitetura modernos, garantindo escalabilidade e facilidade de manutenção, sendo ideal para apresentação acadêmica (TCC) ou como base para soluções corporativas no setor de turismo.

---

## Funcionalidades do Sistema

### 1. Gestão de Itinerários e Grupos
*   **Planejamento Flexível:** Suporte para viagens com roteiros definidos ou modalidade nômade (sem data de término).
*   **Colaboração em Grupo:** Sistema de ingresso via código de convite único, permitindo a gestão multiusuário em um mesmo projeto de viagem.
*   **Controle de Acesso:** Hierarquia de permissões entre Administrador (criador) e Membros.

### 2. Roteirização e Governança Colaborativa
*   **Cronograma de Atividades:** Organização detalhada por data, horário, localização e categoria.
*   **Sistema de Votação:** Mecanismo democrático para aprovação de atividades em grupo, visando a resolução de conflitos no planejamento.

### 3. Gestão Financeira e Divisão de Custos
*   **Lançamento de Despesas:** Registro categorizado de gastos com suporte a múltiplas moedas (conversão base).
*   **Split de Gastos:** Algoritmo de divisão automática de despesas entre membros do grupo, gerando relatórios de "quem deve para quem" em tempo real.

### 4. Inteligência de Comunidade e Serviços
*   **Curadoria de Recomendações:** Biblioteca pessoal de serviços (hospedagem, gastronomia, transporte) com avaliações técnicas e evidências fotográficas.
*   **Módulo de Comunidade:** Feed público para exploração de recomendações de terceiros, com funcionalidade de importação para a biblioteca privada.

### 5. Documentação e Segurança
*   **Diário de Bordo Digital:** Registro de memórias com análise de humor (mood tracking) e galeria de fotos sincronizada.
*   **Álbum em Tempo Real:** Compartilhamento de link externo para visualização pública do progresso da viagem por familiares ou seguidores.
*   **Monitoramento de Segurança:** Ferramenta de check-in de localização e alertas de status para a rede de contatos.

---

## Especificações Técnicas
*   **Framework:** Flutter (Dart)
*   **Backend:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
*   **Gerenciamento de Estado:** Controller Pattern (Pattern-based abstraction)
*   **Integrações:** Share Plus (Social Sharing), Image Picker (Captura de Mídia), Intl (Internacionalização).

---

## Garantia de Qualidade e Testes
O projeto conta com uma suíte de testes automatizados que cobrem as principais regras de negócio.

### Execução dos Testes
Para validar a integridade do sistema, execute o seguinte comando no terminal:
```bash
flutter test
```

Os testes abrangem:
1.  **Modelos de Dados:** Validação de integridade e parsing de objetos.
2.  **Lógica Financeira:** Precisão nos cálculos de divisão de despesas.
3.  **Regras de Negócio:** Permissões de usuários e fluxos de votação.
4.  **Integração de Componentes:** Fluxo de dados entre modelos e controladores.
