// File generated based on Firebase project: edutrack-ai-942c2
// Project: EduTrack-AI
// Generated: 2026-04-19

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50',
    appId: '1:943106194319:android:6802798cb332f33de4a9fa',
    messagingSenderId: '943106194319',
    projectId: 'edutrack-ai-942c2',
    storageBucket: 'edutrack-ai-942c2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50',
    appId: '1:943106194319:ios:edutrackaiios942c2',
    messagingSenderId: '943106194319',
    projectId: 'edutrack-ai-942c2',
    storageBucket: 'edutrack-ai-942c2.appspot.com',
    iosBundleId: 'com.edutrack.ai',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50',
    appId: '1:943106194319:ios:edutrackaimacos942c2',
    messagingSenderId: '943106194319',
    projectId: 'edutrack-ai-942c2',
    storageBucket: 'edutrack-ai-942c2.appspot.com',
    iosBundleId: 'com.edutrack.ai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50',
    appId: '1:943106194319:web:5cf0afda8c8ea44be4a9fa',
    messagingSenderId: '943106194319',
    projectId: 'edutrack-ai-942c2',
    authDomain: 'edutrack-ai-942c2.firebaseapp.com',
    storageBucket: 'edutrack-ai-942c2.firebasestorage.app',
    measurementId: 'G-RXJHP2RZPS',
  );
}
