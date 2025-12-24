import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Clase para obtener las opciones de Firebase según la plataforma
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBdijaLC50tA9N4xF6Oyo9c24ZpBorU6M0',
    appId: '1:40406620278:web:REEMPLAZAR_CON_WEB_APP_ID',
    messagingSenderId: '40406620278',
    projectId: 'mi-comprobante-rd',
    authDomain: 'mi-comprobante-rd.firebaseapp.com',
    storageBucket: 'mi-comprobante-rd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdijaLC50tA9N4xF6Oyo9c24ZpBorU6M0',
    appId: '1:40406620278:android:REEMPLAZAR_CON_ANDROID_APP_ID',
    messagingSenderId: '40406620278',
    projectId: 'mi-comprobante-rd',
    storageBucket: 'mi-comprobante-rd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdijaLC50tA9N4xF6Oyo9c24ZpBorU6M0',
    appId: '1:40406620278:ios:daccc2a6153d79ed66e757',
    messagingSenderId: '40406620278',
    projectId: 'mi-comprobante-rd',
    storageBucket: 'mi-comprobante-rd.firebasestorage.app',
    iosBundleId: 'com.innovadom.miComprobanteRd',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBdijaLC50tA9N4xF6Oyo9c24ZpBorU6M0',
    appId: '1:40406620278:ios:REEMPLAZAR_CON_MACOS_APP_ID',
    messagingSenderId: '40406620278',
    projectId: 'mi-comprobante-rd',
    storageBucket: 'mi-comprobante-rd.firebasestorage.app',
    iosBundleId: 'com.innovadom.miComprobanteRd',
  );
}

