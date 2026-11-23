import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for LeaseShield.
///
/// Replace these placeholder values by running:
/// ```bash
/// dart pub global activate flutterfire_cli
/// flutterfire configure --project=<your-firebase-project-id>
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'LeaseShield targets Android and iOS for on-device Firebase AI Logic.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8yUqH0n7PxXqVPiaFFn5Lbk7bGzueDNU',
    appId: '1:563296314744:android:1b1a01a32c3c008dc7148d',
    messagingSenderId: '563296314744',
    projectId: 'leaseshield-6474a',
    storageBucket: 'leaseshield-6474a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCs3SCdf4fFohgPAgYY9wVn-mJ6pBfC0nM',
    appId: '1:563296314744:ios:06d709e2ed6badc2c7148d',
    messagingSenderId: '563296314744',
    projectId: 'leaseshield-6474a',
    storageBucket: 'leaseshield-6474a.firebasestorage.app',
    iosBundleId: 'com.leaseshield.leaseShield',
  );
  static bool get isPlaceholder =>
      android.apiKey.startsWith('REPLACE_WITH_') ||
      ios.apiKey.startsWith('REPLACE_WITH_');
}
