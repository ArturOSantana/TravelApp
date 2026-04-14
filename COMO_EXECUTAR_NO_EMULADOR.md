# Como Executar o Travel App no Emulador Android

## Passo a Passo Completo

### 1. Verificar Emuladores Disponíveis

```bash
flutter emulators
```

Você verá uma lista como:
```
Id                    • Name                  • Manufacturer • Platform
Pixel_9               • Pixel 9               • Google       • android
Medium_Phone_API_36.1 • Medium Phone API 36.1 • Generic      • android
```

### 2. Iniciar o Emulador Android

Escolha um emulador da lista e inicie:

```bash
flutter emulators --launch Pixel_9
```

**Aguarde 30-60 segundos** para o emulador inicializar completamente.

### 3. Verificar se o Emulador Está Conectado

```bash
flutter devices
```

Você deve ver algo como:
```
sdk gphone16k arm64 (mobile) • emulator-5554 • android-arm64 • Android 15 (API 36)
```

### 4. Executar o App no Emulador

```bash
flutter run
```

Se houver múltiplos dispositivos, especifique o Android:
```bash
flutter run -d emulator-5554
```

---

## Solução de Problemas

### Problema: "No devices found"

**Solução:**
1. Certifique-se de que o emulador está rodando (você deve ver a janela do emulador)
2. Aguarde mais alguns segundos
3. Execute `flutter devices` novamente

### Problema: Emulador não inicia

**Solução:**
```bash
# Abrir Android Studio
# Tools > Device Manager > Criar novo emulador
```

### Problema: Erro de compilação

**Solução:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Executar no macOS (Alternativa)

Se o emulador Android não funcionar, você pode testar no macOS:

```bash
flutter run -d macos
```

---

## Executar no Chrome (Web)

Para testar rapidamente no navegador:

```bash
flutter run -d chrome
```

**Nota:** Algumas funcionalidades (notificações push, offline) funcionam melhor no mobile.

---

## Verificar Status do App

Após executar `flutter run`, você verá:

```
✓ Built build/macos/Build/Products/Debug/travel_app.app
Launching lib/main.dart on macOS in debug mode...
```

O app abrirá automaticamente e você verá:
1. **Tela de Onboarding** (primeira vez)
2. **Tela de Login** (após completar onboarding)

---

## Hot Reload Durante Desenvolvimento

Com o app rodando, você pode fazer alterações no código e:

- Pressione `r` no terminal para hot reload
- Pressione `R` para hot restart
- Pressione `q` para sair

---

## Comandos Úteis

```bash
# Listar dispositivos
flutter devices

# Listar emuladores
flutter emulators

# Limpar build
flutter clean

# Atualizar dependências
flutter pub get

# Executar testes
flutter test

# Build para release (Android)
flutter build apk

# Build para release (iOS)
flutter build ios
```

---

## Testando as Melhorias Implementadas

### 1. Testar Onboarding
- Desinstale o app
- Reinstale e execute
- Onboarding deve aparecer automaticamente
- Complete os 4 slides
- Após completar, não aparece mais

### 2. Testar Offline
- Abra o app com internet
- Navegue pelas viagens
- Desligue WiFi/dados móveis
- Dados ainda devem estar disponíveis
- Faça alterações (serão sincronizadas depois)

### 3. Testar Cache
- Feche e abra o app várias vezes
- Deve carregar mais rápido após a primeira vez
- Dados do usuário são carregados do cache

### 4. Testar Notificações (Android/iOS)
- Crie uma viagem ativa
- Adicione despesas até 80% do orçamento
- Notificação deve aparecer
- Clique na notificação para navegar

---

## Próximos Passos

Após testar no emulador:

1. **Testar em dispositivo físico:**
   ```bash
   # Conecte seu celular via USB
   # Ative "Depuração USB" nas configurações do desenvolvedor
   flutter run
   ```

2. **Gerar APK para distribuição:**
   ```bash
   flutter build apk --release
   # APK estará em: build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Publicar na Play Store:**
   - Criar conta de desenvolvedor Google Play
   - Configurar assinatura do app
   - Upload do APK/AAB

---

**Desenvolvido com Flutter** 🚀