// Firebase configuration options for ChunkUp app
// This file needs to be generated using Firebase CLI:
// firebase init
// flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:web:your-web-app-id',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    authDomain: 'chunkup-350fb.firebaseapp.com',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:android:1cfc4865c0a7fe0bb4ea6d',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:ios:your-ios-app-id',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
    iosBundleId: 'com.chunkup.vocab',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:macos:your-macos-app-id',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
    iosBundleId: 'com.chunkup.vocab',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:windows:your-windows-app-id',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    authDomain: 'chunkup-350fb.firebaseapp.com',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAsN-OXtiUQ-Dfe6h-ubXB7XyTxWXYshGk',
    appId: '1:727961380120:linux:your-linux-app-id',
    messagingSenderId: '727961380120',
    projectId: 'chunkup-350fb',
    authDomain: 'chunkup-350fb.firebaseapp.com',
    storageBucket: 'chunkup-350fb.firebasestorage.app',
    measurementId: 'G-MEASUREMENT_ID',
  );
}