import 'dart:typed_data';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/safety_remote_data_source.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  const SafetyRepositoryImpl({required this.remoteDataSource});

  final SafetyRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  }) => _guard(
    () => remoteDataSource.reportUser(
      targetUserId: targetUserId,
      reason: reason,
      details: details,
    ),
  );

  @override
  Future<Result<void>> blockUser(String targetUserId) =>
      _guard(() => remoteDataSource.blockUser(targetUserId));

  @override
  Future<Result<void>> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  }) => _guard(
    () => remoteDataSource.moderatePhoto(fileName: fileName, bytes: bytes),
  );

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }
}
