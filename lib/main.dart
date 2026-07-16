import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/parlour_provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Attempt Firebase initialization with configuration options
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB8JT7__rwaWRzyEzIJEeUSwCT05VLCljc",
        authDomain: "selvi-s-beauty-parlour.firebaseapp.com",
        projectId: "selvi-s-beauty-parlour",
        storageBucket: "selvi-s-beauty-parlour.firebasestorage.app",
        messagingSenderId: "1054885257137",
        appId: "1:1054885257137:android:210b3a260c0bb39911a790",
      ),
    );
    AuthService.setUseFirebase(true);
    debugPrint("Firebase successfully initialized in Flutter app.");
    // Seeding is deliberately not done here: the security rules deny reads and
    // writes to signed-out clients. ParlourProvider seeds once a user signs in.
  } catch (e) {
    AuthService.setUseFirebase(false);
    debugPrint("Firebase not initialized. Falling back to offline mode. Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadCurrentUser()),
        ChangeNotifierProvider(create: (_) => ParlourProvider()..initializeData()),
      ],
      child: const ParlourApp(),
    ),
  );
}
