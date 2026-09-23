import 'dart:typed_data';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/report_reason.dart';

/// **Placeholder data source.** Real backends: a Firestore `reports`
/// collection + block list, and a managed moderation API (AWS Rekognition
/// / Google Vision — see REQUIREMENTS.md FR-6.3) for photos.
///
/// [getBlockedIds] exists for other features' *data* sources (matching)
/// to filter with — the domain layers stay independent of each other.
abstract interface class SafetyRemoteDataSource {
  Future<void> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  });
  Future<void> blockUser(String targetUserId);
  Future<Set<String>> getBlockedIds();
  Future<void> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  });
}

class MockSafetyRemoteDataSource implements SafetyRemoteDataSource {
  final Set<String> _blocked = {};
  final List<({String targetUserId, ReportReason reason, String? details})>
  _reports = [];

  @override
  Future<void> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _reports.add((
      targetUserId: targetUserId,
      reason: reason,
      details: details,
    ));
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _blocked.add(targetUserId);
  }

  @override
  Future<Set<String>> getBlockedIds() async => Set.unmodifiable(_blocked);

  /// Mock rule: any file whose name contains "unsafe" is rejected, so the
  /// rejection path can be exercised by hand — a real moderation API
  /// looks at the pixels, not the name.
  @override
  Future<void> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (fileName.toLowerCase().contains('unsafe')) {
      throw ServerException(
        '"$fileName" uygunsuz içerik nedeniyle reddedildi.',
      );
    }
  }
}
