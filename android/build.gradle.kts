// 기본 설정
allprojects {
    repositories {
        google()
        mavenCentral()
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