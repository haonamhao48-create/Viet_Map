import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and load dotenv in parallel to optimize startup time
  try {
    await Future.wait([
      dotenv.load(fileName: 'assets/config/env').catchError((_) {
        debugPrint('Dotenv load failed, skipping...');
      }),
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    ]);
  } catch (e) {
    debugPrint('Parallel init failed: $e. Retrying Firebase alone...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  }

  runApp(
    const ProviderScope(
      child: VNMapApp(),
    ),
  );
}