// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyBqvg60gu-cR3QsiiJKTMYAY_-A5zJFsAk',
    appId: '1:205532801648:web:120fd2fe4ff4cc28bb62b5',
    messagingSenderId: '205532801648',
    projectId: 'chatapp-ac786',
    authDomain: 'chatapp-ac786.firebaseapp.com',
    storageBucket: 'chatapp-ac786.appspot.com',
    measurementId: 'G-YZCCME7GW0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW3LWIHRFm9BFj6euIo5vFw9oMoS7R8FQ',
    appId: '1:205532801648:android:ec5c1789f112973bbb62b5',
    messagingSenderId: '205532801648',
    projectId: 'chatapp-ac786',
    storageBucket: 'chatapp-ac786.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzz-_vggTO4uLfGfoTjjbVHiD_8kWV8vg',
    appId: '1:205532801648:ios:1f03f7b6fd28c56bbb62b5',
    messagingSenderId: '205532801648',
    projectId: 'chatapp-ac786',
    storageBucket: 'chatapp-ac786.appspot.com',
    iosBundleId: 'com.example.chatapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzz-_vggTO4uLfGfoTjjbVHiD_8kWV8vg',
    appId: '1:205532801648:ios:1f03f7b6fd28c56bbb62b5',
    messagingSenderId: '205532801648',
    projectId: 'chatapp-ac786',
    storageBucket: 'chatapp-ac786.appspot.com',
    iosBundleId: 'com.example.chatapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBqvg60gu-cR3QsiiJKTMYAY_-A5zJFsAk',
    appId: '1:205532801648:web:d877c655f3006693bb62b5',
    messagingSenderId: '205532801648',
    projectId: 'chatapp-ac786',
    authDomain: 'chatapp-ac786.firebaseapp.com',
    storageBucket: 'chatapp-ac786.appspot.com',
    measurementId: 'G-HV2HS6P1WC',
  );
}