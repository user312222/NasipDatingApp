import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/error_log.dart';

FirebaseException _firestoreError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  group('isSessionEndNoise', () {
    test('a listener rejected after sign-out is noise', () {
      expect(
        isSessionEndNoise(
          _firestoreError('permission-denied'),
          signedIn: false,
        ),
        isTrue,
      );
    });

    test('the same rejection while signed in is a real failure', () {
      expect(
        isSessionEndNoise(_firestoreError('permission-denied'), signedIn: true),
        isFalse,
      );
    });

    test('other Firestore errors are reported even when signed out', () {
      expect(
        isSessionEndNoise(_firestoreError('unavailable'), signedIn: false),
        isFalse,
      );
    });

    test('non-Firebase errors are always reported', () {
      expect(isSessionEndNoise(StateError('boom'), signedIn: false), isFalse);
    });
  });

  group('logFailure', () {
    late List<String> printed;
    late DebugPrintCallback original;

    setUp(() {
      printed = [];
      original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    });

    tearDown(() => debugPrint = original);

    test('prints the scope and the error', () {
      logFailure('feed.stream', StateError('boom'));

      expect(printed.single, startsWith('[feed.stream] '));
      expect(printed.single, contains('boom'));
    });

    // Firebase is not initialised in unit tests, so the sign-in state is
    // unknown - nothing may be hidden in that case.
    test('hides nothing when the sign-in state cannot be read', () {
      logFailure('messaging.stream', _firestoreError('permission-denied'));
      logFailure(
        'waitlist',
        _firestoreError('permission-denied'),
        needsSession: false,
      );

      expect(printed, hasLength(2));
    });
  });
}
