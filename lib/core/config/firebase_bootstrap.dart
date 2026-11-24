import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'remote_config_service.dart';

/// Result of Firebase initialization at startup.
class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.firebaseReady,
    required this.appCheckReady,
    required this.remoteConfigReady,
    required this.uid,
    this.warningMessage,
  });

  final bool firebaseReady;
  final bool appCheckReady;
  final bool remoteConfigReady;
  final String? uid;
  final String? warningMessage;
}

/// Initializes Firebase Core, Firebase App Check, Remote Config, and Anonymous Auth.
///
/// Designed for zero-friction hackathon evaluation:
/// - Debug builds use [AndroidProvider.debug] / [AppleProvider.debug].
/// - Release builds use [AndroidProvider.playIntegrity] / [AppleProvider.appAttest].
/// - If Firebase credentials are placeholders or offline, the app still boots cleanly
///   in privacy-first offline mode.
class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize(
    RemoteConfigService remoteConfigService,
  ) async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('REPLACE_WITH_')) {
      debugPrint(
        '[LeaseShield] Placeholder FirebaseOptions detected. '
        'Run `flutterfire configure` to enable Cloud Gemini & Firestore sync.',
      );
      return const FirebaseBootstrapResult(
        firebaseReady: false,
        appCheckReady: false,
        remoteConfigReady: false,
        uid: null,
        warningMessage:
            'Running in local-only mode. Run flutterfire configure to enable Cloud Gemini & Firestore sync.',
      );
    }

    var firebaseReady = false;
    var appCheckReady = false;
    String? uid;
    String? warning;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
    } catch (e) {
      debugPrint('[LeaseShield] Firebase.initializeApp failed: $e');
      return FirebaseBootstrapResult(
        firebaseReady: false,
        appCheckReady: false,
        remoteConfigReady: false,
        uid: null,
        warningMessage: 'Firebase unavailable ($e). Running in offline-first mode.',
      );
    }

    // 1. Firebase App Check (Mandatory for Firebase AI Logic protection)
    // Uses Debug provider in debug builds or when explicitly requested via
    // `--dart-define=USE_APP_CHECK_DEBUG=true` (for sideloaded judge APKs);
    // uses Play Integrity / App Attest in standard store release builds.
    const forceDebugAppCheck =
        bool.fromEnvironment('USE_APP_CHECK_DEBUG', defaultValue: false);
    final useDebugProvider = kDebugMode || forceDebugAppCheck;
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: useDebugProvider
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider:
            useDebugProvider ? AppleProvider.debug : AppleProvider.appAttest,
      );
      appCheckReady = true;
    } catch (e) {
      debugPrint('[LeaseShield] App Check activation warning: $e');
      warning = 'App Check activation warning: $e';
    }

    // 2. Firebase Remote Config
    await remoteConfigService.initialize();

    // 3. Firebase Auth (Anonymous sign-in by default for zero judge friction)
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        final cred = await auth.signInAnonymously();
        uid = cred.user?.uid;
      } else {
        uid = auth.currentUser?.uid;
      }
    } catch (e) {
      debugPrint('[LeaseShield] Anonymous Auth warning: $e');
      warning ??= 'Offline or Auth disabled; history will stay local until online.';
    }

    return FirebaseBootstrapResult(
      firebaseReady: firebaseReady,
      appCheckReady: appCheckReady,
      remoteConfigReady: remoteConfigService.isInitialized,
      uid: uid,
      warningMessage: warning,
    );
  }
}
