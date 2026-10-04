import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/config/app_check.dart';

void main() {
  group('appCheckModeFor', () {
    test('stays off until a site key is set', () {
      expect(appCheckModeFor(siteKey: '', debug: false), AppCheckMode.off);
      expect(appCheckModeFor(siteKey: '', debug: true), AppCheckMode.off);
      expect(appCheckModeFor(siteKey: '   ', debug: false), AppCheckMode.off);
    });

    test('debug builds use the debug provider', () {
      expect(
        appCheckModeFor(siteKey: '6Lc_example', debug: true),
        AppCheckMode.debug,
      );
    });

    test('release builds attest for real', () {
      expect(
        appCheckModeFor(siteKey: '6Lc_example', debug: false),
        AppCheckMode.attested,
      );
    });
  });

  // Firebase is not initialised in unit tests: with no key this returns
  // before touching it, and with a key the failed activation is swallowed.
  test('activation never throws, configured or not', () async {
    expect(
      await activateAppCheck(),
      appCheckModeFor(siteKey: kAppCheckWebSiteKey, debug: true),
    );
  });
}
