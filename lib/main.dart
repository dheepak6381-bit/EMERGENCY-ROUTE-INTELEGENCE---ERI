import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'data/services/local_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously so Firestore writes are auth-gated.
  // If this fails (e.g. Anonymous Auth not enabled in console), log a warning
  // but still launch the app — reads remain open and offline mode works fine.
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('[ERI] Anonymous auth succeeded');
  } catch (e) {
    debugPrint('[ERI] ⚠ Anonymous auth failed: $e — app will still launch');
  }

  // Initialize the Massive 70k Offline Database in the background
  LocalDatabaseService.instance.init();

  runApp(
    const ProviderScope(
      child: EriApp(),
    ),
  );
}
