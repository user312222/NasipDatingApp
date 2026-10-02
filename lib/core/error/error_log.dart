import 'package:flutter/foundation.dart';

/// Technical failure details (Firebase error codes, stack of what went
/// wrong) go to the developer console only - the text a user sees comes
/// from a plain Turkish [ServerException] message. Swap the body for a
/// crash-reporting call (Crashlytics/Sentry) before launch.
void logFailure(String scope, Object error) => debugPrint('[$scope] $error');
