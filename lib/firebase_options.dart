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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'DUMMY_API_KEY_WEB',
    appId: '1:1234567890:web:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'childsafety-dummy',
    authDomain: 'childsafety-dummy.firebaseapp.com',
    storageBucket: 'childsafety-dummy.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'DUMMY_API_KEY_ANDROID',
    appId: '1:1234567890:android:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'childsafety-dummy',
    storageBucket: 'childsafety-dummy.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'DUMMY_API_KEY_IOS',
    appId: '1:1234567890:ios:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'childsafety-dummy',
    storageBucket: 'childsafety-dummy.appspot.com',
    iosBundleId: 'com.example.childsafety',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'DUMMY_API_KEY_MACOS',
    appId: '1:1234567890:ios:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'childsafety-dummy',
    storageBucket: 'childsafety-dummy.appspot.com',
    iosBundleId: 'com.example.childsafety.macos',
  );
}
