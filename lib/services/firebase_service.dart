import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Centralized manager for Firebase initialization.
///
/// Ensures resilient initialization across Android and non-Android test environments.
/// If Firebase cannot be initialized (offline, test harness, or unsupported platform),
/// it logs the issue and allows the game to function in offline mode without crashing.
class FirebaseService {
  static bool _initialized = false;
  static Object? _initError;

  /// Whether Firebase has been successfully initialized.
  static bool get isInitialized => _initialized;

  /// The error encountered during initialization, if any.
  static Object? get initError => _initError;

  /// For testing: manually set initialization state.
  @visibleForTesting
  static void setInitializedForTesting(bool value, {Object? error}) {
    _initialized = value;
    _initError = error;
  }

  /// Initializes Firebase if not already initialized.
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.android,
        );
        _initialized = true;
        _initError = null;
        debugPrint('FirebaseService: Initialized successfully for Android.');
        return true;
      } else {
        // Non-Android platforms (e.g., Windows desktop development, tests):
        // DefaultFirebaseOptions throws UnsupportedError, so attempt bare initializeApp
        // or gracefully fall back to offline mode.
        try {
          await Firebase.initializeApp();
          _initialized = true;
          _initError = null;
          debugPrint('FirebaseService: Initialized with default platform options.');
          return true;
        } catch (e) {
          _initialized = false;
          _initError = e;
          debugPrint('FirebaseService: Platform default initialization skipped ($e). Offline mode active.');
          return false;
        }
      }
    } catch (e) {
      _initialized = false;
      _initError = e;
      debugPrint('FirebaseService: Firebase initialization failed ($e). Offline mode active.');
      return false;
    }
  }
}
