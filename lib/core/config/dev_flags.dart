import 'package:flutter/foundation.dart';

/// Toggle for Firebase Phone Auth's reCAPTCHA challenge.
///
/// `true` disables Firebase's bot/abuse check entirely, via
/// `FirebaseAuth.setSettings(appVerificationDisabledForTesting: true)` —
/// Firebase's own documented testing flag. It only has any effect when
/// paired with a number added under Firebase Console → Authentication →
/// Phone → "Phone numbers for testing", so it's safe for our own closed-beta
/// test accounts.
///
/// Tied to [kDebugMode] so it cannot be forgotten: `flutter run` (debug)
/// skips the challenge for the test numbers, while every release build
/// (`flutter build ...`) keeps it on. That check is exactly what keeps
/// phone verification from being abused for spam/fake accounts once real
/// users sign up with their own numbers.
const bool kDisableRecaptchaForTesting = kDebugMode;
