import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/result/result.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/router/profile_status_cache.dart';
import 'package:binasip/core/router/route_access.dart';
import 'package:binasip/features/auth/domain/entities/account_type.dart';
import 'package:binasip/features/auth/domain/entities/auth_user.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/repositories/profile_repository.dart';
import 'package:binasip/features/profile/domain/usecases/has_profile.dart';

final _verifiedAt = DateTime(2026, 1, 1);

final _single = AuthUser(id: 's', phone: '5550000000', verifiedAt: _verifiedAt);
const _unverified = AuthUser(id: 'u', phone: '5550000009');
final _guardian = AuthUser(
  id: 'g',
  phone: '5550000002',
  accountType: AccountType.guardian,
  verifiedAt: _verifiedAt,
);

const _appRoutes = [
  '/discover',
  '/feed',
  '/matches',
  '/account',
  '/family/settings',
];

class _FakeProfileRepository implements ProfileRepository {
  Result<bool> result = const Ok(false);
  var reads = 0;

  @override
  Future<Result<bool>> hasProfile(String userId) async {
    reads++;
    return result;
  }

  @override
  Future<Result<void>> saveProfile(Profile profile) =>
      throw UnimplementedError();
}

void main() {
  group('signed out', () {
    const nobody = AccessContext();

    test('public pages are open', () {
      expect(accessRedirect('/', nobody), isNull);
      expect(accessRedirect('/waitlist', nobody), isNull);
    });

    test('every page of the app sends back to the entry screen', () {
      for (final location in [
        ..._appRoutes,
        '/chat',
        '/settings',
        '/selfie-verification',
        '/onboarding-complete',
        '/profile/photos',
        '/profile/complete',
        '/guardian/home',
        '/guardian/link',
      ]) {
        expect(accessRedirect(location, nobody), '/', reason: location);
      }
    });
  });

  group('registration door: steps cannot be skipped by address', () {
    test('account type and consent need an accepted invite code', () {
      const none = AccessContext();
      const invited = AccessContext(inviteAccepted: true);

      for (final location in ['/account-type', '/consent']) {
        expect(accessRedirect(location, none), '/', reason: location);
        expect(accessRedirect(location, invited), isNull, reason: location);
      }
    });

    test('the phone step needs the invite code and the consent', () {
      expect(accessRedirect('/phone', const AccessContext()), '/');
      expect(
        accessRedirect('/phone', const AccessContext(inviteAccepted: true)),
        '/',
      );
      expect(
        accessRedirect('/phone', const AccessContext(consentAccepted: true)),
        '/',
      );
      expect(
        accessRedirect(
          '/phone',
          const AccessContext(inviteAccepted: true, consentAccepted: true),
        ),
        isNull,
      );
    });

    test('the code step needs a requested code', () {
      expect(accessRedirect('/otp', const AccessContext()), '/');
      expect(
        accessRedirect('/otp', const AccessContext(otpRequested: true)),
        isNull,
      );
    });
  });

  group('sign-in door', () {
    test('goes straight to the phone step, but to nothing else', () {
      const signingIn = AccessContext(signingIn: true);

      expect(accessRedirect('/phone', signingIn), isNull);
      expect(accessRedirect('/account-type', signingIn), '/');
      expect(accessRedirect('/consent', signingIn), '/');
      expect(accessRedirect('/discover', signingIn), '/');
    });
  });

  group('signed in but not verified yet (FR-1.2)', () {
    const access = AccessContext(user: _unverified);

    test('only the liveness step is open', () {
      expect(accessRedirect('/selfie-verification', access), isNull);
      for (final location in [
        ..._appRoutes,
        '/settings',
        '/profile/photos',
        '/onboarding-complete',
        '/guardian/home',
      ]) {
        expect(
          accessRedirect(location, access),
          '/selfie-verification',
          reason: location,
        );
      }
    });
  });

  group('single account without a profile', () {
    final access = AccessContext(user: _single, hasProfile: false);

    test('the app proper sends to the profile wizard', () {
      for (final location in [..._appRoutes, '/chat']) {
        expect(
          accessRedirect(location, access),
          '/profile/photos',
          reason: location,
        );
      }
    });

    test('the wizard is open, its last page is not', () {
      for (final location in [
        '/profile/photos',
        '/profile/privacy',
        '/profile/intent',
        '/profile/details',
        '/profile/family',
      ]) {
        expect(accessRedirect(location, access), isNull, reason: location);
      }
      expect(accessRedirect('/profile/complete', access), '/profile/photos');
    });

    test('settings stay reachable, guardian pages do not', () {
      expect(accessRedirect('/settings', access), isNull);
      expect(accessRedirect('/guardian/home', access), '/profile/photos');
      expect(accessRedirect('/selfie-verification', access), '/profile/photos');
    });
  });

  group('single account with a profile', () {
    final access = AccessContext(user: _single, hasProfile: true);

    test('the whole app is open', () {
      for (final location in [
        ..._appRoutes,
        '/settings',
        '/profile/complete',
        '/onboarding-complete',
      ]) {
        expect(accessRedirect(location, access), isNull, reason: location);
      }
    });

    test('chat needs a conversation to show', () {
      expect(accessRedirect('/chat', access), '/matches');
      expect(
        accessRedirect(
          '/chat',
          AccessContext(user: _single, hasProfile: true, hasChatArgs: true),
        ),
        isNull,
      );
    });

    test('guardian pages and the finished liveness step send home', () {
      expect(accessRedirect('/guardian/home', access), '/discover');
      expect(accessRedirect('/guardian/link', access), '/discover');
      expect(accessRedirect('/selfie-verification', access), '/discover');
    });

    test('an unknown profile state never locks the user out', () {
      final unknown = AccessContext(user: _single);

      for (final location in _appRoutes) {
        expect(accessRedirect(location, unknown), isNull, reason: location);
      }
    });
  });

  group('guardian account (FR-8.6)', () {
    final access = AccessContext(user: _guardian);

    test('reaches its own pages and settings', () {
      expect(accessRedirect('/guardian/home', access), isNull);
      expect(accessRedirect('/guardian/link', access), isNull);
      expect(accessRedirect('/settings', access), isNull);
      expect(accessRedirect('/onboarding-complete', access), isNull);
    });

    test('nothing of the single user’s app', () {
      for (final location in [
        ..._appRoutes,
        '/chat',
        '/profile/photos',
        '/profile/complete',
      ]) {
        expect(
          accessRedirect(location, access),
          '/guardian/home',
          reason: location,
        );
      }
    });

    test('not even a chat that was handed its arguments', () {
      expect(
        accessRedirect(
          '/chat',
          AccessContext(user: _guardian, hasChatArgs: true),
        ),
        '/guardian/home',
      );
    });
  });

  group('needsProfileCheck', () {
    test('only a verified single on the app proper', () {
      expect(needsProfileCheck('/discover', _single), isTrue);
      expect(needsProfileCheck('/chat', _single), isTrue);
      expect(needsProfileCheck('/profile/complete', _single), isTrue);

      expect(needsProfileCheck('/profile/photos', _single), isFalse);
      expect(needsProfileCheck('/settings', _single), isFalse);
      expect(needsProfileCheck('/discover', _guardian), isFalse);
      expect(needsProfileCheck('/discover', _unverified), isFalse);
      expect(needsProfileCheck('/discover', null), isFalse);
    });
  });

  group('ProfileStatusCache', () {
    late _FakeProfileRepository repo;
    late ProfileStatusCache cache;

    setUp(() {
      repo = _FakeProfileRepository();
      cache = ProfileStatusCache(HasProfile(repo));
    });

    test('remembers a profile, so later checks cost nothing', () async {
      repo.result = const Ok(true);

      expect(await cache.check('s'), isTrue);
      expect(await cache.check('s'), isTrue);

      expect(repo.reads, 1);
      expect(cache.isKnown('s'), isTrue);
    });

    test(
      'does not remember a missing profile (the wizard may finish)',
      () async {
        expect(await cache.check('s'), isFalse);
        expect(cache.isKnown('s'), isFalse);

        repo.result = const Ok(true);
        expect(await cache.check('s'), isTrue);
        expect(repo.reads, 2);
      },
    );

    test('a failed read is unknown, not a no', () async {
      repo.result = const Err(ServerFailure('Profil okunamadı.'));

      expect(await cache.check('s'), isNull);
      expect(cache.isKnown('s'), isFalse);
    });

    test('is per account', () async {
      repo.result = const Ok(true);
      await cache.check('s');

      expect(cache.isKnown('someone_else'), isFalse);
    });
  });
}
