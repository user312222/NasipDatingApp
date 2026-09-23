import '../../../../core/result/result.dart';

abstract interface class ConsentRepository {
  /// Persists that [userId] accepted both the data-processing and the
  /// cross-border-transfer notices on `ConsentScreen`, at [consentVersion].
  /// Called right after OTP verification succeeds (the earliest point a
  /// uid exists) for a **new** registration — never for a restored/
  /// returning session, since consent was already recorded the first time.
  Future<Result<void>> recordConsent({
    required String userId,
    required String consentVersion,
  });
}
