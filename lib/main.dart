/// Entry point for the Sanbao mobile application.
///
/// Initializes services (Sentry, SharedPreferences, local DB) and
/// wraps the app in a Riverpod [ProviderScope] with required
/// provider overrides.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/app.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/core/storage/local_db.dart';
import 'package:sanbao_flutter/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await ErrorHandler.initialize(
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp();

      // Lock orientation to portrait on phones
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI overlay style for light status bar
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFFAFBFD),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Initialize SharedPreferences (sync access after await)
      final sharedPreferences = await SharedPreferences.getInstance();

      // Initialize local file-based database for offline caching
      final localDb = LocalDatabase();
      await localDb.initialize();

      // Run the app with Riverpod provider scope
      runApp(
        ProviderScope(
          overrides: [
            // Override providers that require async initialization
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            localDatabaseProvider.overrideWithValue(localDb),
          ],
          child: const SanbaoApp(),
        ),
      );
    },
  );
}
