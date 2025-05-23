# Androidx Window 관련 클래스 보존
-keep class androidx.window.** { *; }
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.sidecar.** { *; }

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Coroutines and kotlin
-keep class kotlinx.coroutines.**  { *; }
-dontwarn kotlinx.coroutines.**

# dotenv
-keep class io.flutter.plugins.** { *; }

# API related
-keep class com.android.okhttp.** { *; }
-keep interface com.android.okhttp.** { *; }
-dontwarn com.android.okhttp.**

# Http related
-dontwarn org.apache.http.**
-dontwarn android.net.http.**

# Gson related
-keep class com.google.gson.** { *; }
-keep class com.google.**
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }

# Keep model classes
-keep class com.chunkup.vocab.domain.models.** { *; }
-keepclassmembers class com.chunkup.vocab.domain.models.** { *; }

# Keep Freezed and json serializable code
-keep class **.*$Freezed { *; }
-keep class **.*$Json { *; }
-keepclassmembers class **.*$Freezed { *; }
-keepclassmembers class **.*$Json { *; }

# Google Mobile Ads
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep public class com.google.android.gms.ads.** {
   public *;
}

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Flutter TTS
-keep class com.tundek.flutter_tts.** { *; }

# File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Connectivity
-keep class com.shounakmulay.telephony.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Zip
-keep class net.lingala.zip4j.** { *; }
-dontwarn net.lingala.zip4j.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Others
-dontwarn java.nio.file.**
-dontwarn org.codehaus.mojo.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**