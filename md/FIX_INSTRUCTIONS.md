# Android SDK Version Fix

The google_mobile_ads plugin requires a minimum Android SDK version of 23, but your app is currently configured to use SDK version 21.

## How to Fix

### Option 1: Update minSdkVersion (Recommended)

1. Open the file `android/app/build.gradle` in your project
2. Locate the `defaultConfig` section
3. Change `minSdkVersion 21` to `minSdkVersion 23`

Your code should look like this:

```gradle
defaultConfig {
    applicationId "com.example.chunk_up"  // This may be different in your file
    // You can update the following values to match your application needs.
    minSdkVersion 23  // Updated from 21 for google_mobile_ads compatibility
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

### Option 2: Override Library (Not Recommended)

If you absolutely need to support Android SDK 21, you can force usage of the library with the following steps:

1. Open the file `android/app/src/main/AndroidManifest.xml`
2. Add the following to the `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.chunk_up">
    
    <uses-sdk tools:overrideLibrary="io.flutter.plugins.googlemobileads" />
    
    <!-- Rest of your manifest -->
</manifest>
```

**Warning:** This approach might lead to runtime crashes on devices with Android versions below 23.

## Impact

After updating to minSdkVersion 23, your app will no longer be available to users running Android 5.0 (Lollipop) or earlier. This represents a very small percentage of Android users as of 2023-2024.

## Alternative Approach

If supporting older Android versions is critical for your app, consider using a different ad provider plugin that supports Android SDK 21, or implement conditional ad loading based on the Android version.