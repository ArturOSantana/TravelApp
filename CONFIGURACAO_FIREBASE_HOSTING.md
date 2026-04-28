# 🔥 Configuração do Firebase Hosting para Compartilhamento de Álbuns

## Visão Geral

Este guia explica como configurar o Firebase Hosting para permitir o compartilhamento público de registros de viagem através de links web.

## Pré-requisitos

- Firebase CLI instalado (`npm install -g firebase-tools`)
- Projeto Firebase já configurado
- Conta Google com acesso ao projeto

## Passo 1: Configurar Firebase Hosting

### 1.1 Fazer login no Firebase CLI

```bash
firebase login
```

### 1.2 Inicializar Hosting (se ainda não foi feito)

```bash
firebase init hosting
```

Selecione:
- ✅ Use an existing project (selecione seu projeto)
- 📁 Public directory: `web`
- ✅ Configure as a single-page app: `No`
- ✅ Set up automatic builds: `No`
- ⚠️ File web/index.html already exists. Overwrite? `No`

### 1.3 Atualizar firebase.json

O arquivo `firebase.json` já está configurado, mas verifique se contém:

```json
{
  "hosting": {
    "public": "web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/album**",
        "destination": "/album.html"
      }
    ]
  }
}
```

## Passo 2: Configurar Credenciais do Firebase na Página Web

### 2.1 Obter configuração do Firebase

1. Acesse o [Console do Firebase](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em **Configurações do Projeto** (ícone de engrenagem)
4. Role até **Seus apps** e clique em **Web** (ícone </>)
5. Copie o objeto `firebaseConfig`

### 2.2 Atualizar web/album.html

Abra `web/album.html` e substitua as credenciais na linha ~320:

```javascript
const firebaseConfig = {
    apiKey: "SUA_API_KEY_AQUI",
    authDomain: "seu-projeto.firebaseapp.com",
    projectId: "seu-projeto-id",
    storageBucket: "seu-projeto.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abc123"
};
```

## Passo 3: Fazer Deploy

### 3.1 Build do projeto (opcional, para testar localmente)

```bash
flutter build web
```

### 3.2 Deploy para Firebase Hosting

```bash
firebase deploy --only hosting
```

### 3.3 Verificar URL de deploy

Após o deploy, você receberá uma URL como:
```
https://seu-projeto.web.app
```

## Passo 4: Testar o Compartilhamento

### 4.1 Gerar um token de compartilhamento

No app, ao criar um registro de diário:
1. Marque a opção "Tornar público"
2. O sistema gerará automaticamente um `shareToken`
3. O link será: `https://seu-projeto.web.app/album?token=SHARE_TOKEN`

### 4.2 Compartilhar o link

Use o botão de compartilhar no app para enviar o link via:
- WhatsApp
- Email
- Redes sociais
- Copiar para área de transferência

## Passo 5: Configurar Regras de Segurança do Firestore

Atualize `firestore.rules` para permitir leitura pública de registros compartilhados:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir leitura pública de registros compartilhados
    match /trips/{tripId}/journal/{entryId} {
      allow read: if resource.data.isPublic == true;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Outras regras...
  }
}
```

Deploy das regras:
```bash
firebase deploy --only firestore:rules
```

## Funcionalidades Implementadas

### ✅ Página Web de Álbum (`web/album.html`)

- **Design Responsivo**: Funciona em desktop e mobile
- **Galeria de Fotos**: Grid adaptativo com modal de visualização
- **Indicador de Humor**: Exibe o emoji e cor do humor registrado
- **Reações em Tempo Real**: Atualiza automaticamente quando alguém reage
- **Informações Completas**: Usuário, localização, data, conteúdo
- **Animações Suaves**: Transições e efeitos visuais modernos

### ✅ Backend de Reações

**Métodos no TripController:**

1. **`addReactionToJournalEntry()`**
   - Adiciona ou remove reação de um usuário
   - Previne múltiplas reações do mesmo tipo
   - Atualiza em tempo real

2. **`generateShareToken()`**
   - Gera token único para compartilhamento
   - Marca registro como público
   - Retorna token para criar link

3. **`getPublicJournalEntry()`**
   - Busca registro público por token
   - Valida se está público
   - Retorna dados completos

4. **`watchJournalEntry()`**
   - Stream para acompanhar mudanças em tempo real
   - Atualiza reações automaticamente
   - Mantém sincronização

### ✅ Interface de Reações

**Barra de Reações no Journal:**
- 6 tipos de reações com ícones Material Design
- Contador de reações por tipo
- Indicador visual quando usuário já reagiu
- Cores específicas para cada tipo de reação
- Acessibilidade com Semantics

## Tipos de Reações Disponíveis

| Tipo | Ícone | Cor | Descrição |
|------|-------|-----|-----------|
| like | ❤️ | Vermelho | Curtir |
| love | 💕 | Rosa | Amei |
| wow | ⭐ | Amarelo | Uau |
| celebrate | 🎉 | Laranja | Celebrar |
| support | 👍 | Azul | Apoiar |
| thanks | 🙏 | Roxo | Obrigado |

## Fluxo Completo de Uso

### 1. Criar Registro Público

```dart
// No app Flutter
final entry = JournalEntry(
  // ... outros campos
  isPublic: true,  // Marcar como público
);

// Gerar token de compartilhamento
final token = await controller.generateShareToken(tripId, entryId);
final shareUrl = 'https://seu-projeto.web.app/album?token=$token';
```

### 2. Compartilhar Link

```dart
// Usar share_plus para compartilhar
await Share.share(
  'Confira meu registro de viagem!\n$shareUrl',
  subject: 'Álbum de Viagem',
);
```

### 3. Visualizar na Web

1. Usuário abre o link no navegador
2. Página carrega dados do Firestore
3. Exibe fotos, conteúdo e reações
4. Atualiza em tempo real quando há novas reações

### 4. Reagir ao Registro

- Visitantes podem ver as reações existentes
- Contadores atualizam em tempo real
- Interface responsiva e intuitiva

## Troubleshooting

### Erro: "Token não encontrado"

**Causa**: Token inválido ou registro não público  
**Solução**: Verificar se `isPublic: true` e `shareToken` estão definidos

### Erro: "Permission denied"

**Causa**: Regras do Firestore não permitem leitura pública  
**Solução**: Atualizar `firestore.rules` conforme Passo 5

### Página não carrega

**Causa**: Credenciais do Firebase incorretas  
**Solução**: Verificar `firebaseConfig` em `web/album.html`

### Reações não atualizam

**Causa**: Listener não configurado corretamente  
**Solução**: Verificar se `setupRealtimeUpdates()` está sendo chamado

## Melhorias Futuras Sugeridas

- [ ] Adicionar autenticação para reagir (opcional)
- [ ] Permitir comentários nos registros
- [ ] Adicionar mais tipos de reações
- [ ] Implementar analytics de visualizações
- [ ] Criar página de galeria com múltiplos registros
- [ ] Adicionar opção de download de fotos
- [ ] Implementar PWA para instalação
- [ ] Adicionar modo escuro

## Recursos Adicionais

- [Documentação Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Documentação Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

## Suporte

Para problemas ou dúvidas:
1. Verifique os logs do Firebase Console
2. Teste localmente com `firebase serve`
3. Consulte a documentação oficial do Firebase

---

**Última atualização**: 28/04/2026  
**Versão**: 1.0.0