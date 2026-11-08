import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class LocalDemo {
  static const enabled = bool.fromEnvironment('FOODFIGHT_LOCAL_DEMO');
  static const host = '127.0.0.1';
  static const options = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123:web:foodfightdemo',
    messagingSenderId: '123',
    projectId: 'demo-food-fight',
    storageBucket: 'demo-food-fight.appspot.com',
  );

  static Future<void> connect() async {
    if (!kIsWeb || !kDebugMode) {
      throw StateError('Food Fight local demo requires a debug web build.');
    }

    final app = await Firebase.initializeApp(options: options);
    if (app.options.projectId != options.projectId) {
      throw StateError('Unexpected Firebase project in local demo.');
    }

    await FirebaseAuth.instance.useAuthEmulator(host, 9187);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8687);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5687);
    await FirebaseStorage.instance.useStorageEmulator(host, 9287);
  }
}
