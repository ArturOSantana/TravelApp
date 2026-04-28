# 🔐 Instruções para Autenticação GitHub CLI

## 📋 Status Atual

O comando `gh auth login` está aguardando sua autenticação no navegador.

## ✅ Passos para Completar a Autenticação

### 1. Abrir URL no Navegador

Abra esta URL no seu navegador:
```
https://github.com/login/device
```

### 2. Inserir o Código

O terminal deve ter exibido um código de 8 caracteres (formato: XXXX-XXXX).

**Copie esse código** e cole na página do GitHub.

### 3. Autorizar GitHub CLI

1. Faça login no GitHub (se necessário)
2. Cole o código de autenticação
3. Clique em **"Continue"**
4. Revise as permissões solicitadas
5. Clique em **"Authorize github"**

### 4. Confirmar no Terminal

Após autorizar no navegador, volte ao terminal e aguarde a confirmação:
```
✓ Authentication complete.
✓ Logged in as ArturOSantana
```

## 🚀 Após Autenticação Bem-Sucedida

Execute o push:
```bash
git push origin main
```

O GitHub CLI automaticamente usará as credenciais corretas com todos os scopes necessários, incluindo `workflow`.

## 🎯 O Que Acontecerá Depois

1. **Push bem-sucedido** para branch `main`
2. **GitHub Actions** será acionado automaticamente
3. **Workflow CI/CD** iniciará com 2 jobs:
   - ✅ **test** (15 min): Análise + Testes
   - ✅ **build** (30 min): Build + Deploy

4. **Após ~45 minutos**:
   - APK disponível no Firebase App Distribution
   - Release criada no GitHub
   - Artefatos disponíveis para download

## 📊 Monitorar o Workflow

Após o push, acesse:
```
https://github.com/ArturOSantana/TravelApp/actions
```

Você verá o workflow **"Firebase App Distribution"** em execução.

## 🔍 Verificar Logs

Clique no workflow para ver:
- ✅ Logs de cada job
- ✅ Tempo de execução
- ✅ Artefatos gerados
- ✅ Status de cada step

## ⚠️ Se Houver Erro

### Erro: "Resource not accessible by integration"

**Solução**: Configurar secret `FIREBASE_SERVICE_ACCOUNT`

1. Acesse Firebase Console: https://console.firebase.google.com
2. Selecione projeto: **travel-app-tcc**
3. Vá em: **Project Settings** → **Service Accounts**
4. Clique em: **Generate new private key**
5. Baixe o arquivo JSON
6. Copie todo o conteúdo do JSON
7. Acesse GitHub: https://github.com/ArturOSantana/TravelApp/settings/secrets/actions
8. Clique em: **New repository secret**
9. Name: `FIREBASE_SERVICE_ACCOUNT`
10. Value: [Cole o conteúdo do JSON]
11. Clique em: **Add secret**

### Erro: "Codecov token not found"

**Solução**: Configurar secret `CODECOV_TOKEN` (opcional)

1. Acesse: https://codecov.io
2. Faça login com GitHub
3. Adicione o repositório TravelApp
4. Copie o token
5. Adicione como secret no GitHub

**OU** remova a step de Codecov do workflow (não é crítico).

## 📝 Comandos Úteis

### Verificar status da autenticação:
```bash
gh auth status
```

### Fazer logout (se necessário):
```bash
gh auth logout
```

### Fazer login novamente:
```bash
gh auth login
```

### Ver informações do repositório:
```bash
gh repo view
```

### Listar workflows:
```bash
gh workflow list
```

### Ver runs do workflow:
```bash
gh run list
```

### Ver logs do último run:
```bash
gh run view --log
```

## 🎓 Referências

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

---

**Próximo passo**: Abra a URL no navegador e complete a autenticação! 🚀