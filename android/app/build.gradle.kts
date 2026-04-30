plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.travel_app"
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Habilita desugaring para suporte a APIs de data/hora em versões antigas do Android
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.travel_app"
        // Suporte para Android 5.0 (Lollipop) e superior - cobre 99%+ dos dispositivos
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Otimizações para dispositivos antigos
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // Otimizações para reduzir tamanho do APK (ProGuard/R8)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // Desabilita otimizações em debug para build mais rápido
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Configurações para reduzir tamanho do APK
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

dependencies {
    // Adiciona a biblioteca de desugaring exigida pelo flutter_local_notifications
    // Atualizado para 2.1.4 conforme exigido pela versão do plugin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
