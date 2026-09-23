import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../entities/report_reason.dart';

abstract interface class SafetyRepository {
  /// FR-6.1.
  Future<Result<void>> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  });

  /// FR-6.2: after this, [targetUserId] never appears again in discovery
  /// or in this account's matches.
  Future<Result<void>> blockUser(String targetUserId);

  /// FR-6.3: fails with a user-facing message when the photo is rejected.
  Future<Result<void>> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  });
}
