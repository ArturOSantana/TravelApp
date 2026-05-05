  Guia de Contribuição

Obrigado por considerar contribuir com o Travel App! Este documento fornece diretrizes para contribuir com o projeto.

  Código de Conduta

 Nossos Padrões

-  Seja respeitoso e inclusivo
-  Aceite críticas construtivas
-  Foque no que é melhor para a comunidade
-  Mostre empatia com outros membros

 Comportamentos Inaceitáveis

-  Linguagem ou imagens sexualizadas
-  Trolling ou comentários insultuosos
-  Assédio público ou privado
-  Publicar informações privadas de outros

  Como Contribuir

 . Reportar Bugs

Antes de criar um issue:
- Verifique se o bug já foi reportado
- Use a busca do GitHub
- Inclua informações detalhadas

Template de Bug Report:
```markdown
Descrição do Bug
Descrição clara e concisa do problema.

Passos para Reproduzir
. Vá para '...'
. Clique em '...'
. Role até '...'
. Veja o erro

Comportamento Esperado
O que deveria acontecer.

Screenshots
Se aplicável, adicione screenshots.

Ambiente:
 - OS: [ex: iOS ]
 - Versão do App: [ex: ..]
 - Dispositivo: [ex: iPhone ]
```

 . Sugerir Melhorias

Template de Feature Request:
```markdown
Problema Relacionado
Descrição clara do problema que a feature resolve.

Solução Proposta
Descrição clara da solução desejada.

Alternativas Consideradas
Outras soluções que você considerou.

Contexto Adicional
Qualquer outro contexto ou screenshots.
```

 . Pull Requests

 Processo

. Fork o repositório
```bash
git clone https://github.com/seu-usuario/TCC.git
cd TCC
```

. Crie uma branch
```bash
git checkout -b feature/minha-feature
 ou
git checkout -b fix/meu-bugfix
```

. Faça suas alterações
- Siga o style guide
- Adicione testes
- Atualize documentação

. Commit suas mudanças
```bash
git add .
git commit -m "feat: adiciona nova funcionalidade X"
```

. Push para o GitHub
```bash
git push origin feature/minha-feature
```

. Abra um Pull Request

 Convenção de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé opcional]
```

Tipos:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Apenas documentação
- `style`: Formatação, ponto e vírgula, etc
- `refactor`: Refatoração de código
- `test`: Adicionar testes
- `chore`: Manutenção

Exemplos:
```bash
feat(auth): adiciona login com Google
fix(expenses): corrige cálculo de divisão
docs(readme): atualiza instruções de instalação
style(dashboard): formata código com dartfmt
refactor(services): simplifica chamadas de API
test(trip): adiciona testes unitários
chore(deps): atualiza dependências
```

  Configuração do Ambiente

 Pré-requisitos

```bash
 Verificar Flutter
flutter doctor -v

 Versão mínima
Flutter ..
Dart ..
```

 Instalação

```bash
 Clonar repositório
git clone https://github.com/seu-usuario/TCC.git
cd TCC

 Instalar dependências
flutter pub get

 Configurar Firebase (se necessário)
 Adicione seus arquivos de configuração

 Executar
flutter run
```

  Style Guide

 Dart/Flutter

Seguimos o [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
//  BOM
class UserProfile {
  final String name;
  final String email;
  
  UserProfile({
    required this.name,
    required this.email,
  });
}

//  RUIM
class user_profile {
  String Name;
  String Email;
}
```

 Formatação

```bash
 Formatar código
dart format .

 Analisar código
flutter analyze

 Executar testes
flutter test
```

 Nomenclatura

- Classes: PascalCase (`UserProfile`)
- Variáveis: camelCase (`userName`)
- Constantes: lowerCamelCase (`maxRetries`)
- Arquivos: snake_case (`user_profile.dart`)

 Comentários

```dart
/// Documentação de classe ou método público.
///
/// Usa três barras e markdown.
class Example {
  // Comentário de implementação interna
  void _privateMethod() {
    // TODO: Implementar funcionalidade
  }
}
```

  Testes

 Executar Testes

```bash
 Todos os testes
flutter test

 Teste específico
flutter test test/user_test.dart

 Com cobertura
flutter test --coverage
```

 Escrever Testes

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('deve criar usuário válido', () {
      final user = UserProfile(
        name: 'João',
        email: 'joao@email.com',
      );
      
      expect(user.name, 'João');
      expect(user.email, 'joao@email.com');
    });
  });
}
```

  Documentação

 Atualizar Documentação

Ao adicionar features:
. Atualize o README.md
. Adicione documentação em `docs/`
. Atualize comentários no código
. Adicione exemplos de uso

 Estrutura

```
docs/
├── README.md                     Índice principal
├── desenvolvimento/              Guias de dev
├── apis/                         Docs de APIs
├── planejamento/                 Roadmap
└── assets/                       Imagens e design
```


  Prioridades

 Alta Prioridade
- Bugs críticos
- Problemas de segurança
- Performance

 Média Prioridade
- Novas features
- Melhorias de UX
- Refatorações

 Baixa Prioridade
- Documentação
- Testes adicionais
- Otimizações menores

  Comunicação

 Canais

- Issues: Para bugs e features
- Discussions: Para perguntas gerais
- Pull Requests: Para código

 Tempo de Resposta

- Issues: - dias úteis
- Pull Requests: - dias úteis
- Perguntas: - dias úteis

  Reconhecimento

Contribuidores serão:
- Listados no README
- Mencionados nas release notes
- Creditados no app (se significativo)

  Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto.

---

Obrigado por contribuir! 

Para dúvidas, abra uma issue ou discussion.