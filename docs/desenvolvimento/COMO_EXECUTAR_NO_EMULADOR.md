  Como Executar o Travel App no Emulador

Guia completo para executar o aplicativo em diferentes emuladores e dispositivos.

  Pré-requisitos

 Ferramentas Necessárias
-  Flutter SDK .. ou superior
-  Dart SDK (incluído no Flutter)
-  Git
-  Editor de código (VS Code recomendado)

 Verificar Instalação
```bash
flutter doctor -v
```

Este comando verifica se todas as dependências estão instaladas corretamente.

---

  Android

 Opção : Emulador Android (AVD)

 . Instalar Android Studio
- Baixe em: https://developer.android.com/studio
- Instale o Android SDK
- Configure as variáveis de ambiente

 . Criar um Emulador
```bash
 Abrir o AVD Manager
android studio > Tools > AVD Manager > Create Virtual Device
```

Configurações Recomendadas:
- Dispositivo: Pixel  ou superior
- API Level:  (Android ) ou superior
- RAM: GB mínimo
- Armazenamento: GB mínimo

 . Iniciar o Emulador
```bash
 Listar emuladores disponíveis
flutter emulators

 Iniciar emulador específico
flutter emulators --launch <emulator_id>

 Ou iniciar pelo Android Studio
```

 . Executar o App
```bash
 Verificar dispositivos conectados
flutter devices

 Executar no emulador
flutter run

 Ou especificar o dispositivo
flutter run -d <device_id>
```

 Opção : Dispositivo Físico Android

 . Habilitar Modo Desenvolvedor
. Vá em Configurações > Sobre o telefone
. Toque  vezes em Número da versão
. Volte e acesse Opções do desenvolvedor
. Ative Depuração USB

 . Conectar via USB
```bash
 Verificar conexão
adb devices

 Executar o app
flutter run
```

 . Conectar via Wi-Fi (Opcional)
```bash
 Conectar via USB primeiro
adb tcpip 

 Obter IP do dispositivo (Configurações > Wi-Fi)
adb connect <IP_DO_DISPOSITIVO>:

 Desconectar USB e executar
flutter run
```

---

  iOS

 Requisitos
- ️ Apenas macOS
- Xcode  ou superior
- Conta Apple Developer (gratuita para testes)

 Opção : Simulador iOS

 . Instalar Xcode
```bash
 Via App Store ou
xcode-select --install
```

 . Listar Simuladores
```bash
 Ver simuladores disponíveis
xcrun simctl list devices

 Ou via Flutter
flutter emulators
```

 . Iniciar Simulador
```bash
 Abrir simulador padrão
open -a Simulator

 Ou via Flutter
flutter emulators --launch apple_ios_simulator
```

 . Executar o App
```bash
 Instalar pods (primeira vez)
cd ios
pod install
cd ..

 Executar
flutter run -d ios
```

 Opção : Dispositivo Físico iOS

 . Configurar Certificado
. Abra o projeto no Xcode: `open ios/Runner.xcworkspace`
. Selecione Runner no navegador
. Vá em Signing & Capabilities
. Selecione sua Team (conta Apple)

 . Confiar no Desenvolvedor
. No iPhone: Configurações > Geral > Gerenciamento de Dispositivo
. Confie no certificado do desenvolvedor

 . Executar
```bash
flutter run -d <device_id>
```

---

  Web

 Executar no Navegador

```bash
 Chrome (recomendado)
flutter run -d chrome

 Edge
flutter run -d edge

 Firefox
flutter run -d firefox

 Safari (macOS)
flutter run -d safari
```

 Modo de Desenvolvimento
```bash
 Com hot reload
flutter run -d chrome --web-renderer html

 Ou com CanvasKit (melhor performance)
flutter run -d chrome --web-renderer canvaskit
```

 Build para Produção
```bash
flutter build web --release
```

Os arquivos serão gerados em `build/web/`

---

  Desktop

 Windows

 Requisitos
- Visual Studio 
- C++ Desktop Development workload

 Executar
```bash
flutter run -d windows
```

 Build
```bash
flutter build windows --release
```

 macOS

 Requisitos
- Xcode Command Line Tools

 Executar
```bash
flutter run -d macos
```

 Build
```bash
flutter build macos --release
```

 Linux

 Requisitos
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk--dev
```

 Executar
```bash
flutter run -d linux
```

 Build
```bash
flutter build linux --release
```

---

  Comandos Úteis

 Desenvolvimento
```bash
 Hot reload (r no terminal)
r

 Hot restart (R no terminal)
R

 Limpar build
flutter clean

 Obter dependências
flutter pub get

 Atualizar dependências
flutter pub upgrade

 Verificar problemas
flutter doctor

 Analisar código
flutter analyze
```

 Debug
```bash
 Modo debug (padrão)
flutter run

 Modo profile (performance)
flutter run --profile

 Modo release
flutter run --release

 Com logs detalhados
flutter run -v
```

 Múltiplos Dispositivos
```bash
 Listar dispositivos
flutter devices

 Executar em dispositivo específico
flutter run -d <device_id>

 Executar em todos os dispositivos
flutter run -d all
```

---

  Solução de Problemas

 Android

Problema: Emulador não inicia
```bash
 Verificar virtualização
 Windows: Habilitar Hyper-V ou HAXM
 Linux: Verificar KVM

 Recriar emulador
flutter emulators --create
```

Problema: Gradle build falha
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

 iOS

Problema: Pod install falha
```bash
cd ios
pod deintegrate
pod install
cd ..
```

Problema: Certificado inválido
- Verificar conta Apple Developer
- Reconfigurar Signing no Xcode

 Geral

Problema: Dependências desatualizadas
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

Problema: Cache corrompido
```bash
flutter clean
rm -rf ~/.pub-cache
flutter pub get
```

---

  Performance

 Otimizações para Emulador

Android:
- Use x_ em vez de ARM
- Ative aceleração de hardware
- Aumente RAM do emulador (GB+)

iOS:
- Use simuladores mais recentes
- Feche apps desnecessários
- Ative Metal rendering

Geral:
- Use modo profile para testes de performance
- Desative hot reload em testes finais
- Monitore uso de memória

---

  Dicas Rápidas

. Use VS Code com extensão Flutter para melhor experiência
. Mantenha apenas um emulador aberto por vez
. Use hot reload (r) em vez de hot restart (R) quando possível
. Teste em dispositivos reais antes de lançar
. Configure atalhos para comandos frequentes

---

  Recursos Adicionais

- [Documentação Flutter](https://flutter.dev/docs)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Android Studio](https://developer.android.com/studio)
- [Xcode](https://developer.apple.com/xcode/)

---

Última atualização: Maio   
Versão: ..