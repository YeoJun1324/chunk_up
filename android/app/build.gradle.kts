plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.chunk_vocab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // 명시적 출력 디렉토리 설정
    buildDir = File(rootProject.buildDir, "app")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Core library desugaring 활성화
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.chunk_vocab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Updated from 21 to 23 for google_mobile_ads plugin
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 멀티덱스 지원 추가
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // ProGuard 규칙 추가
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // R8 최적화 비활성화 (빌드 문제 해결용)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// dependencies 블록
dependencies {
    // Core library desugaring 의존성 - 2.1.4 버전으로 업데이트
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // 멀티덱스 지원 의존성
    implementation("androidx.multidex:multidex:2.0.1")

    // Window 확장 라이브러리 추가
    implementation("androidx.window:window:1.2.0")
    implementation("androidx.window:window-java:1.2.0")
}

flutter {
    source = "../.."
}