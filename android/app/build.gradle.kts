plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase用の設定
    id("com.google.gms.google-services")
}

android {
    // 自分のプロジェクト名に合わせる
    namespace = "com.example.run_for_money"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // ★追加: デシュガーリングの有効化（エラー対策）
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // 自分のプロジェクト名に合わせる
        applicationId = "com.example.run_for_money"
        // ★修正: Android 5.0 (API 21) 以上を要求
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ★追加: デシュガーリング用のライブラリ（エラー対策）
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
