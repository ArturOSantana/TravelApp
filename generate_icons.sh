#!/bin/bash

# Script para gerar ícones do app em todos os tamanhos necessários
# Autor: Assistente de Desenvolvimento
# Data: $(date)

echo "🎨 Gerador de Ícones para Flutter App"
echo "======================================"

# Verificar se a imagem original existe
if [ ! -f "app_icon_original.png" ]; then
    echo "❌ Erro: Coloque sua imagem como 'app_icon_original.png' na pasta raiz do projeto"
    echo "📋 A imagem deve ser:"
    echo "   - Formato PNG"
    echo "   - Tamanho mínimo: 1024x1024px"
    echo "   - Fundo transparente (recomendado)"
    exit 1
fi

# Verificar se ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick não encontrado!"
    echo "📦 Instale com:"
    echo "   macOS: brew install imagemagick"
    echo "   Ubuntu: sudo apt-get install imagemagick"
    echo "   Windows: baixe do site oficial"
    exit 1
fi

echo "✅ Imagem original encontrada: app_icon_original.png"
echo "✅ ImageMagick instalado"
echo ""

# Criar diretórios se não existirem
echo "📁 Criando diretórios necessários..."
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
mkdir -p web/icons

# Função para gerar ícone com log
generate_icon() {
    local size=$1
    local output=$2
    local platform=$3
    
    convert app_icon_original.png -resize ${size} "${output}"
    if [ $? -eq 0 ]; then
        echo "   ✅ ${platform}: ${size} → ${output}"
    else
        echo "   ❌ Erro ao gerar: ${output}"
    fi
}

# Android Icons
echo ""
echo "📱 Gerando ícones Android..."
generate_icon "48x48" "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" "MDPI"
generate_icon "72x72" "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" "HDPI"
generate_icon "96x96" "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" "XHDPI"
generate_icon "144x144" "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" "XXHDPI"
generate_icon "192x192" "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" "XXXHDPI"

# iOS Icons
echo ""
echo "🍎 Gerando ícones iOS..."
generate_icon "20x20" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png" "iOS"
generate_icon "40x40" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png" "iOS"
generate_icon "60x60" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png" "iOS"
generate_icon "29x29" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png" "iOS"
generate_icon "58x58" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png" "iOS"
generate_icon "87x87" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png" "iOS"
generate_icon "40x40" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png" "iOS"
generate_icon "80x80" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png" "iOS"
generate_icon "120x120" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png" "iOS"
generate_icon "120x120" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png" "iOS"
generate_icon "180x180" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png" "iOS"
generate_icon "76x76" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png" "iOS"
generate_icon "152x152" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" "iOS"
generate_icon "167x167" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" "iOS"
generate_icon "1024x1024" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" "iOS"

# Web Icons
echo ""
echo "🌐 Gerando ícones Web..."
generate_icon "192x192" "web/icons/Icon-192.png" "Web"
generate_icon "512x512" "web/icons/Icon-512.png" "Web"
generate_icon "192x192" "web/icons/Icon-maskable-192.png" "Web"
generate_icon "512x512" "web/icons/Icon-maskable-512.png" "Web"
generate_icon "32x32" "web/favicon.png" "Web"

echo ""
echo "🎉 Ícones gerados com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "1. Execute: flutter clean"
echo "2. Execute: flutter pub get"
echo "3. Teste: flutter run"
echo ""
echo "📁 Arquivos gerados em:"
echo "   📱 Android: android/app/src/main/res/mipmap-*/"
echo "   🍎 iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "   🌐 Web: web/icons/ e web/favicon.png"
echo ""
echo "✨ Seu app agora tem ícones personalizados em todas as plataformas!"

# Made with Bob
