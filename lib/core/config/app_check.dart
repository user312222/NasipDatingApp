import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../error/error_log.dart';

/// The reCAPTCHA v3 **site key** registered for this app under Firebase
/// Console → App Check. A site key is public by design (it ships in every
/// page that uses it), so it lives in the repo.
///
/// Empty means App Check is off and nothing below runs - the state until
/// the key is created. See `docs/LAUNCH_CHECKLIST.md` §1 for the steps.
const String kAppCheckWebSiteKey = '';

/// Optional fixed debug token for `flutter run`, passed with
/// `--dart-define=APP_CHECK_DEBUG_TOKEN=...`. A debug token lets its holder
/// through App Check, so it is never committed. Left empty, the Firebase
/// SDK makes one up and prints it to the console, to be registered under
/// App Check → Apps → Manage debug tokens.
const String _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

enum AppCheckMode {
  /// No site key yet: App Check is not activated at all.
  off,

  /// `flutter run`: the debug provider, so development keeps working once
  /// enforcement is switched on in the Console.
  debug,

  /// Release builds: real attestation (reCAPTCHA v3 on the web, Play
  /// Integrity on Android, DeviceCheck on Apple platforms).
  attested,
}

AppCheckMode appCheckModeFor({required String siteKey, required bool debug}) {
  if (siteKey.trim().isEmpty) return AppCheckMode.off;
  return debug ? AppCheckMode.debug : AppCheckMode.attested;
}

/// Turns App Check on when it is configured. Call once, right after
/// `Firebase.initializeApp` and before the first Firestore/Auth request.
///
/// App Check is what stops scripts that only have the public API key from
/// calling Firestore and phone sign-in directly (the public waitlist write
/// is the obvious target). A failure here must not keep the app from
/// starting: requests then go out without a token, which only matters once
/// enforcement is on.
Future<AppCheckMode> activateAppCheck() async {
  final mode = appCheckModeFor(siteKey: kAppCheckWebSiteKey, debug: kDebugMode);
  if (mode == AppCheckMode.off) return mode;

  final debug = mode == AppCheckMode.debug;
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: debug
          ? WebDebugProvider(
              debugToken: _debugToken.isEmpty ? null : _debugToken,
            )
          : ReCaptchaV3Provider(kAppCheckWebSiteKey),
      providerAndroid: debug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: debug
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  } catch (e) {
    logFailure('app_check', e, needsSession: false);
  }
  return mode;
}
