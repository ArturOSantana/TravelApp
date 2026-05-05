  Configuração do Firebase Hosting

Guia completo para configurar e fazer deploy do Travel App no Firebase Hosting.

  Pré-requisitos

-  Conta Google/Firebase
-  Firebase CLI instalado
-  Projeto Flutter configurado
-  Node.js instalado (para Firebase CLI)

---

  Instalação do Firebase CLI

 Via npm (Recomendado)
```bash
npm install -g firebase-tools
```

 Via Homebrew (macOS)
```bash
brew install firebase-cli
```

 Verificar Instalação
```bash
firebase --version
```

---

  Autenticação

 Login no Firebase
```bash
firebase login
```

Isso abrirá o navegador para autenticação com sua conta Google.

 Verificar Login
```bash
firebase projects:list
```

---

 ️ Configuração do Projeto

 . Inicializar Firebase no Projeto

```bash
 Na raiz do projeto
firebase init
```

 . Selecionar Serviços

Selecione os seguintes serviços:
-  Hosting - Para hospedar a versão web
-  Firestore - Banco de dados
-  Storage - Armazenamento de arquivos
-  Functions (Opcional) - Para funções serverless

 . Configurar Hosting

Perguntas durante a configuração:

```
? What do you want to use as your public directory?
> build/web

? Configure as a single-page app (rewrite all urls to /index.html)?
> Yes

? Set up automatic builds and deploys with GitHub?
> No (ou Yes se quiser CI/CD)

? File build/web/index.html already exists. Overwrite?
> No
```

 . Arquivo firebase.json

O arquivo `firebase.json` deve ficar assim:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "/.",
      "/node_modules/"
    ],
    "rewrites": [
      {
        "source": "",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age="
          }
        ]
      },
      {
        "source": "/.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age="
          }
        ]
      }
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

---

  Build e Deploy

 . Build da Aplicação Web

```bash
 Build de produção
flutter build web --release

 Com otimizações específicas
flutter build web --release --web-renderer canvaskit
```

 . Testar Localmente

```bash
 Servir localmente
firebase serve --only hosting

 Ou
firebase emulators:start --only hosting
```

Acesse: http://localhost:

 . Deploy para Produção

```bash
 Deploy completo
firebase deploy

 Apenas hosting
firebase deploy --only hosting

 Com mensagem de deploy
firebase deploy -m "Versão .. - Lançamento inicial"
```

 . Verificar Deploy

Após o deploy, você receberá URLs como:
- Hosting URL: https://travel-app-tcc.web.app
- Console: https://console.firebase.google.com

---

  Configurações Avançadas

 Múltiplos Ambientes

 . Criar Projetos Separados
```bash
 Desenvolvimento
firebase use --add dev-project-id --alias dev

 Produção
firebase use --add prod-project-id --alias prod
```

 . Deploy por Ambiente
```bash
 Deploy para dev
firebase use dev
firebase deploy

 Deploy para prod
firebase use prod
firebase deploy
```

 Custom Domain

 . Adicionar Domínio
```bash
firebase hosting:channel:deploy production
```

 . No Console Firebase
. Vá em Hosting
. Clique em Add custom domain
. Siga as instruções para configurar DNS

 . Configurar DNS
Adicione os registros DNS fornecidos pelo Firebase:
```
Type: A
Name: @
Value: [IP fornecido pelo Firebase]

Type: A
Name: www
Value: [IP fornecido pelo Firebase]
```

 SSL/HTTPS

O Firebase Hosting fornece SSL automaticamente:
-  Certificado SSL gratuito
-  Renovação automática
-  HTTPS forçado

---

  Regras de Segurança

 Firestore Rules (firestore.rules)

```javascript
rules_version = '';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Viagens
    match /trips/{tripId} {
      allow read: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         request.auth.uid in resource.data.members);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }
    
    // Despesas
    match /trips/{tripId}/expenses/{expenseId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/trips/$(tripId)) &&
        (get(/databases/$(database)/documents/trips/$(tripId)).data.ownerId == request.auth.uid ||
         request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.members);
    }
    
    // Journal
    match /trips/{tripId}/journal/{entryId} {
      allow read: if request.auth != null || 
        get(/databases/$(database)/documents/trips/$(tripId)).data.journalPublic == true;
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/trips/$(tripId)).data.ownerId == request.auth.uid ||
         request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.members);
    }
  }
}
```

 Storage Rules (storage.rules)

```javascript
rules_version = '';
service firebase.storage {
  match /b/{bucket}/o {
    // Fotos de perfil
    match /users/{userId}/profile/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
        request.resource.size <      &&
        request.resource.contentType.matches('image/.');
    }
    
    // Fotos de viagens
    match /trips/{tripId}/photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.resource.size <      &&
        request.resource.contentType.matches('image/.');
    }
  }
}
```

 Deploy das Regras

```bash
 Deploy apenas das regras
firebase deploy --only firestore:rules
firebase deploy --only storage:rules

 Ou todas juntas
firebase deploy --only firestore,storage
```

---

  Monitoramento

 Ver Logs
```bash
firebase hosting:channel:list
```

 Analytics
Acesse o Console Firebase:
. Analytics - Métricas de uso
. Performance - Performance da aplicação
. Crashlytics - Relatórios de erros

---

  CI/CD com GitHub Actions

 . Criar Token de Deploy

```bash
firebase login:ci
```

Copie o token gerado.

 . Adicionar ao GitHub Secrets

. Vá em Settings > Secrets > Actions
. Adicione: `FIREBASE_TOKEN` com o valor do token

 . Criar Workflow (.github/workflows/deploy.yml)

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v
      
      - uses: subosito/flutter-action@v
        with:
          flutter-version: '..'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_TOKEN }}'
          channelId: live
          projectId: travel-app-tcc
```

---

  Solução de Problemas

 Erro: "Permission denied"
```bash
 Re-autenticar
firebase logout
firebase login
```

 Erro: "Build not found"
```bash
 Verificar se o build existe
ls -la build/web

 Rebuild
flutter clean
flutter build web --release
```

 Erro: "Quota exceeded"
- Verifique o plano do Firebase
- Otimize imagens e assets
- Use CDN para arquivos grandes

---

  Dicas de Otimização

 . Compressão de Assets
```bash
 Otimizar imagens antes do build
flutter pub run flutter_launcher_icons:main
```

 . Code Splitting
```dart
// Use lazy loading para rotas
MaterialApp(
  onGenerateRoute: (settings) {
    // Carregamento sob demanda
  },
)
```

 . Cache Strategy
Configure headers de cache no `firebase.json` para melhor performance.

---

  Recursos Adicionais

- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [Flutter Web Deployment](https://flutter.dev/docs/deployment/web)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

Última atualização: Maio   
Versão: ..