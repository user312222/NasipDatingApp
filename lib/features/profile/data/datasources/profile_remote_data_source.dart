import '../../../../core/error/exceptions.dart';
import '../models/profile_model.dart';

/// **Placeholder data source.** Swap for Firestore (profile document) +
/// Firebase Storage (photo upload, replacing `photoRefs` placeholders with
/// real download URLs) once the backend exists — `ProfileRepositoryImpl`
/// and everything above it stays unchanged.
abstract interface class ProfileRemoteDataSource {
  Future<void> save(ProfileModel profile);

  /// See `ProfileRepository.hasProfile`.
  Future<bool> hasProfile(String userId);
}

class MockProfileRemoteDataSource implements ProfileRemoteDataSource {
  final List<ProfileModel> _profiles = [];

  @override
  Future<void> save(ProfileModel profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (profile.photoRefs.isEmpty || profile.photoRefs.length > 6) {
      throw const ServerException('1 ile 6 arası fotoğraf gerekiyor.');
    }
    if (profile.age < 18) {
      throw const ServerException('18 yaşından küçükler kayıt olamaz.');
    }
    _profiles.removeWhere((p) => p.userId == profile.userId);
    _profiles.add(profile);
  }

  @override
  Future<bool> hasProfile(String userId) async =>
      _profiles.any((p) => p.userId == userId);
}
