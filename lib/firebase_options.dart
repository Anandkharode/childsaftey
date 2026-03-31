import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCuO58CnYcsQzRonFboe8-Izy-YKOByTyU',
    appId: '1:511757997969:web:99df83689ba06486052c30',
    messagingSenderId: '511757997969',
    projectId: 'child-59a51',
    authDomain: 'child-59a51.firebaseapp.com',
    storageBucket: 'child-59a51.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtT8w8wFUNf8YtmVPmdkEOJEbDhLYwgVs',
    appId: '1:511757997969:android:6f236bfc731b58ea052c30',
    messagingSenderId: '511757997969',
    projectId: 'child-59a51',
    storageBucket: 'child-59a51.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkhhSRh9r4z6KV0Vj5HJ56d7VcNCVK-48',
    appId: '1:511757997969:ios:9999f63032a38bb1052c30',
    messagingSenderId: '511757997969',
    projectId: 'child-59a51',
    storageBucket: 'child-59a51.firebasestorage.app',
    iosBundleId: 'com.example.child',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCkhhSRh9r4z6KV0Vj5HJ56d7VcNCVK-48',
    appId: '1:511757997969:ios:9999f63032a38bb1052c30',
    messagingSenderId: '511757997969',
    projectId: 'child-59a51',
    storageBucket: 'child-59a51.firebasestorage.app',
    iosBundleId: 'com.example.child',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCuO58CnYcsQzRonFboe8-Izy-YKOByTyU',
    appId: '1:511757997969:web:696ef6e6b9e024a6052c30',
    messagingSenderId: '511757997969',
    projectId: 'child-59a51',
    authDomain: 'child-59a51.firebaseapp.com',
    storageBucket: 'child-59a51.firebasestorage.app',
  );

}