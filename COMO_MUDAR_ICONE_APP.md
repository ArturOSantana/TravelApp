# Como Mudar o Ícone do App (Logo)

## Jeito Mais Simples e Rápido

### Passo 1: Preparar sua Logo

Você precisa de uma imagem PNG com:
- **Tamanho**: 1024x1024 pixels (mínimo)
- **Formato**: PNG com fundo transparente (recomendado) ou com cor sólida
- **Design**: Simples e reconhecível em tamanhos pequenos

### Passo 2: Instalar o Pacote

```bash
flutter pub add --dev flutter_launcher_icons
```

### Passo 3: Adicionar sua Logo no Projeto

Coloque sua imagem de logo em:
```
assets/icon/app_icon.png
```

Se a pasta `assets/icon/` não existir, crie ela.

### Passo 4: Configurar no pubspec.yaml

Adicione no final do arquivo `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  
  # Para Android (ícone adaptativo - recomendado)
  adaptive_icon_background: "#FFFFFF"  # Cor de fundo (mude para a cor que quiser)
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  
  # Para iOS
  remove_alpha_ios: true
```

### Passo 5: Gerar os Ícones

Execute o comando:

```bash
flutter pub run flutter_launcher_icons
```

### Passo 6: Pronto! 🎉

Agora é só fazer o build e distribuir:

```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release
```

## Exemplo Completo do pubspec.yaml

```yaml
name: app_travel
description: App de viagens

dependencies:
  flutter:
    sdk: flutter
  # ... suas outras dependências

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.13.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/icon/app_icon.png
    - assets/images/

# Configuração do ícone
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  remove_alpha_ios: true
```

## Dicas Importantes

1. **Tamanho da Imagem**: Use pelo menos 1024x1024px
2. **Fundo Transparente**: Melhor para ícones adaptativos no Android
3. **Design Simples**: Evite textos pequenos ou detalhes muito finos
4. **Teste**: Depois de gerar, teste no emulador para ver como ficou

## Se Algo Der Errado

Se o ícone não mudar:

1. Limpe o projeto:
```bash
flutter clean
flutter pub get
```

2. Gere os ícones novamente:
```bash
flutter pub run flutter_launcher_icons
```

3. Faça o build novamente:
```bash
flutter build apk --release
```

## Ferramentas Online para Criar Logo

Se você não tem uma logo ainda:

1. **Canva** (https://canva.com) - Gratuito, fácil de usar
2. **Figma** (https://figma.com) - Profissional, gratuito
3. **Logo Maker** - Apps no celular

---

**É só isso!** Bem mais simples do que parecia, né? 😊