import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_data_source.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl({required this.remoteDataSource});

  final MessagingRemoteDataSource remoteDataSource;

  @override
  Future<Result<Conversation>> openConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) => _guard(
    () => remoteDataSource.openConversation(
      matchId: matchId,
      otherPartyName: otherPartyName,
      otherPartyAvatarSeed: otherPartyAvatarSeed,
    ),
  );

  @override
  Future<Result<Conversation>> sendMessage({
    required String matchId,
    required String text,
  }) =>
      _guard(() => remoteDataSource.sendMessage(matchId: matchId, text: text));

  @override
  Future<Result<void>> dismissFamilyNudge(String matchId) =>
      _guard(() => remoteDataSource.dismissFamilyNudge(matchId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }
}
