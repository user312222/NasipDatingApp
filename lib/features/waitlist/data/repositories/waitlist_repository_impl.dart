import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/waitlist_entry.dart';
import '../../domain/repositories/waitlist_repository.dart';
import '../datasources/waitlist_local_data_source.dart';
import '../models/waitlist_entry_model.dart';

class WaitlistRepositoryImpl implements WaitlistRepository {
  const WaitlistRepositoryImpl({required this.localDataSource});

  final WaitlistLocalDataSource localDataSource;

  @override
  Future<Result<void>> submit(WaitlistEntry entry) async {
    try {
      await localDataSource.submit(WaitlistEntryModel.fromEntity(entry));
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Kayıt gönderilemedi.'));
    }
  }
}
