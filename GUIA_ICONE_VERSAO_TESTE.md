# Guia: Ícone Diferente para Versões de Teste (Firebase App Distribution)

## Visão Geral

Sim, é possível e **altamente recomendado** usar um ícone diferente para versões de teste distribuídas via Firebase App Distribution. Isso ajuda testadores a distinguirem facilmente entre a versão de produção e a versão de teste do app.

## Estratégias Recomendadas

### 1. **Abordagem Recomendada: Build Flavors (Variantes)**

Esta é a melhor prática profissional, permitindo ter versões completamente separadas do app.

#### Para Android

**Passo 1: Configurar Build Flavors**

Edite `android/app/build.gradle.kts`:

```kotlin
android {
    // ... outras configurações
    
    flavorDimensions += "version"
    
    productFlavors {
        create("production") {
            dimension = "version"
            applicationIdSuffix = ""
            versionNameSuffix = ""
            resValue("string", "app_name", "AppTravel")
        }
        
        create("beta") {
            dimension = "version"
            applicationIdSuffix = ".beta"
            versionNameSuffix = "-beta"
            resValue("string", "app_name", "AppTravel Beta")
        }
        
        create("dev") {
            dimension = "version"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "AppTravel Dev")
        }
    }
}
```

**Passo 2: Criar Estrutura de Ícones**

Crie as seguintes pastas:
```
android/app/src/
├── production/
│   └── res/
│       ├── mipmap-hdpi/ic_launcher.png
│       ├── mipmap-mdpi/ic_launcher.png
│       ├── mipmap-xhdpi/ic_launcher.png
│       ├── mipmap-xxhdpi/ic_launcher.png
│       └── mipmap-xxxhdpi/ic_launcher.png
├── beta/
│   └── res/
│       ├── mipmap-hdpi/ic_launcher.png (com badge BETA)
│       ├── mipmap-mdpi/ic_launcher.png
│       ├── mipmap-xhdpi/ic_launcher.png
│       ├── mipmap-xxhdpi/ic_launcher.png
│       └── mipmap-xxxhdpi/ic_launcher.png
└── dev/
    └── res/
        ├── mipmap-hdpi/ic_launcher.png (com badge DEV)
        └── ...
```

#### Para iOS

**Passo 1: Criar Schemes no Xcode**

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Vá em Product > Scheme > Manage Schemes
3. Duplique o scheme "Runner" e renomeie para "Runner-Beta"
4. Duplique novamente para "Runner-Dev"

**Passo 2: Configurar Build Settings**

Para cada scheme:
1. Edit Scheme > Build Configuration
2. Beta: Use "Release-Beta"
3. Dev: Use "Debug-Dev"

**Passo 3: Criar Asset Catalogs Separados**

```
ios/Runner/Assets.xcassets/
├── AppIcon-Production.appiconset/
├── AppIcon-Beta.appiconset/
└── AppIcon-Dev.appiconset/
```

### 2. **Abordagem Simples: flutter_launcher_icons com Badges**

Se você quer algo mais rápido, use o pacote `flutter_launcher_icons` com badges.

**Passo 1: Adicionar Dependência**

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

**Passo 2: Configurar Ícones**

```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  
  # Configuração para versão de produção
  android_adaptive_foreground: "assets/icon/foreground.png"
  android_adaptive_background: "#FFFFFF"
  
  # Para versão beta, você pode criar uma configuração separada
  # e executar com: flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-beta.yaml
```

**Passo 3: Criar Arquivo de Configuração Beta**

```yaml
# flutter_launcher_icons-beta.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon_beta.png"  # Ícone com badge BETA
  android_adaptive_foreground: "assets/icon/foreground_beta.png"
  android_adaptive_background: "#FF6B6B"  # Cor diferente para destacar
```

**Passo 4: Gerar Ícones**

```bash
# Ícone de produção
flutter pub run flutter_launcher_icons:main

# Ícone beta
flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-beta.yaml
```

### 3. **Criar Ícones com Badge**

#### Ferramentas Online Recomendadas:

1. **App Icon Generator** (https://appicon.co/)
   - Upload seu ícone base
   - Adiciona badge "BETA", "TEST", "DEV"
   - Gera todos os tamanhos necessários

2. **MakeAppIcon** (https://makeappicon.com/)
   - Similar ao anterior
   - Suporta badges personalizados

3. **Photoshop/Figma/Canva**
   - Crie manualmente adicionando:
     - Badge no canto (ex: "BETA" em vermelho)
     - Borda colorida diferente
     - Opacidade reduzida
     - Texto sobreposto

#### Exemplo de Design de Badge:

```
Ícone de Produção:
┌─────────────┐
│             │
│   [LOGO]    │
│             │
└─────────────┘

Ícone Beta:
┌─────────────┐
│ ┌─────┐     │
│ │BETA │     │
│ └─────┘     │
│   [LOGO]    │
│             │
└─────────────┘
(Badge vermelho no canto superior)
```

## Workflow Completo para Firebase App Distribution

### Opção 1: Build Manual com Flavors

```bash
# Android - Build Beta
flutter build apk --flavor beta --release

# Android - Build Dev
flutter build apk --flavor dev --release

# iOS - Build Beta
flutter build ipa --flavor beta --release

# Distribuir via Firebase CLI
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-beta-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers \
  --release-notes "Versão Beta para testes"
```

### Opção 2: Automatizar com GitHub Actions

```yaml
# .github/workflows/distribute_beta.yml
name: Distribute Beta to Firebase

on:
  push:
    branches: [ develop ]

jobs:
  build_and_distribute:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Build Beta APK
        run: flutter build apk --flavor beta --release
      
      - name: Distribute to Firebase
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{secrets.FIREBASE_APP_ID}}
          token: ${{secrets.FIREBASE_TOKEN}}
          groups: testers
          file: build/app/outputs/flutter-apk/app-beta-release.apk
          releaseNotes: "Nova versão beta disponível"
```

## Configuração Recomendada para Seu Projeto

### Estrutura Sugerida:

```
assets/icon/
├── app_icon_production.png (1024x1024)
├── app_icon_beta.png (1024x1024 com badge BETA vermelho)
└── app_icon_dev.png (1024x1024 com badge DEV laranja)
```

### Comandos para Gerar:

```bash
# 1. Instalar flutter_launcher_icons
flutter pub add --dev flutter_launcher_icons

# 2. Criar configurações
# Criar flutter_launcher_icons-beta.yaml (veja exemplo acima)

# 3. Gerar ícones
flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-beta.yaml

# 4. Build e distribuir
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups testers
```

## Benefícios

✅ **Identificação Visual Imediata**: Testadores sabem qual versão estão usando
✅ **Instalação Simultânea**: Com flavors, pode ter produção e beta instalados juntos
✅ **Profissionalismo**: Demonstra organização e boas práticas
✅ **Evita Confusão**: Reduz erros de testar na versão errada
✅ **Feedback Mais Preciso**: Testadores reportam bugs na versão correta

## Dicas Importantes

1. **Cores Sugeridas para Badges**:
   - BETA: Vermelho (#FF0000)
   - DEV: Laranja (#FF6B00)
   - STAGING: Amarelo (#FFD700)

2. **Texto do Badge**:
   - Mantenha curto: "BETA", "DEV", "TEST"
   - Use fonte bold e legível
   - Contraste alto com o fundo

3. **Posicionamento**:
   - Canto superior direito ou esquerdo
   - Não cubra elementos importantes do logo
   - Tamanho: ~25-30% do ícone

4. **Documentação**:
   - Informe aos testadores sobre os diferentes ícones
   - Inclua screenshots na documentação de teste

## Próximos Passos

1. Escolha a abordagem (Flavors ou flutter_launcher_icons)
2. Crie os ícones com badges
3. Configure o build
4. Teste localmente
5. Configure Firebase App Distribution
6. Distribua para testadores

## Recursos Adicionais

- [Flutter Flavors Documentation](https://flutter.dev/docs/deployment/flavors)
- [flutter_launcher_icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Android Product Flavors](https://developer.android.com/studio/build/build-variants)

---

**Nota**: O Firebase App Distribution em si não modifica o ícone automaticamente. Você precisa configurar ícones diferentes no build do app antes de distribuir.