/// **Placeholder data source.** A real backend would keep the full
/// history of consent versions per user (for KVKK's burden-of-proof
/// requirement), not just the latest one — see
/// `FirestoreConsentRemoteDataSource` for the real, still-minimal version.
abstract interface class ConsentRemoteDataSource {
  Future<void> recordConsent({
    required String userId,
    required String consentVersion,
  });
}

class MockConsentRemoteDataSource implements ConsentRemoteDataSource {
  final Map<String, String> _recorded = {};

  @override
  Future<void> recordConsent({
    required String userId,
    required String consentVersion,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _recorded[userId] = consentVersion;
  }
}
