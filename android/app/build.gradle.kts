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
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
