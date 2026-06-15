# Travel App

Projeto de TCC da ETEC Desenvolvimento de Sistemas.

## Sobre

O Travel App é um aplicativo para ajudar no planejamento de viagens.

O projeto reúne recursos como:
- organização de viagens
- controle de gastos
- roteiro
- diário de viagem
- lista de mala
- recursos de segurança

## Tecnologias

- Flutter
- Dart
- Firebase

## Como executar

### Requisitos

- Flutter instalado
- Dart instalado
- Android Studio ou VS Code
- Firebase configurado

### Passos

```bash
git clone <url-do-repo>
cd TCC
flutter pub get
flutter run
```

## Configuração de chaves

Se precisar usar APIs externas:

```bash
cp lib/config/api_keys.dart.example lib/config/api_keys.dart
```

Depois preencha as chaves no arquivo `lib/config/api_keys.dart`.

## Estrutura

```text
lib/
├── models/
├── services/
├── screens/
├── widgets/
└── main.dart
```

## Documentação

A documentação complementar está na pasta `docs/`.

Arquivos úteis:
- `docs/README.md`
- `docs/desenvolvimento/COMO_EXECUTAR_NO_EMULADOR.md`
- `docs/desenvolvimento/ORGANIZACAO_REGRAS_NEGOCIO.md`

## Observações

- O projeto ainda possui avisos no `flutter analyze`.
- Arquivos sensíveis como `.env` e `lib/config/api_keys.dart` estão no `.gitignore`.

## Licença

Uso acadêmico.
