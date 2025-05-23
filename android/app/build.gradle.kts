plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 키스토어 프로퍼티 맵
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = mutableMapOf<String, String>()
if (keystorePropertiesFile.exists()) {
    try {
        keystorePropertiesFile.bufferedReader().use { reader ->
            reader.lineSequence()
                .filter { it.contains("=") }
                .forEach {
                    val (key, value) = it.split("=", limit = 2)
                    keystoreProperties[key.trim()] = value.trim()
                }
        }
        println("Successfully loaded key.properties")
    } catch (e: Exception) {
        println("Warning: key.properties exists but could not be loaded: ${e.message}")
    }
} else {
    println("Warning: key.properties file not found, using debug signing config")
}

android {
    namespace = "com.chunkup.vocab"
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

    // 릴리스용 서명 설정 구성
    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = rootProject.file(keystoreProperties["storeFile"]!!)
                storePassword = keystoreProperties["storePassword"]
                keyAlias = keystoreProperties["keyAlias"]
                keyPassword = keystoreProperties["keyPassword"]
            }
        }
    }

    defaultConfig {
        // 실제 출시용 애플리케이션 ID
        applicationId = "com.chunkup.vocab"
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
            // 릴리스 빌드에 릴리스 서명 구성 사용
            if (keystoreProperties.containsKey("storeFile")) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // 키 파일이 없는 경우 디버그 키로 대체
                signingConfig = signingConfigs.getByName("debug")
            }

            // ProGuard 규칙 추가
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // R8 최적화 완전히 비활성화
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
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