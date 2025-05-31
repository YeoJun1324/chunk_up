// 기본 설정
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build script dependencies
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// Android 플러그인 설정
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task 수정
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}