import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_data_source.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl({required this.remoteDataSource});

  final MessagingRemoteDataSource remoteDataSource;

  @override
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) async* {
    try {
      await for (final conversation in remoteDataSource.watchConversation(
        matchId: matchId,
        otherPartyName: otherPartyName,
        otherPartyAvatarSeed: otherPartyAvatarSeed,
      )) {
        yield Ok(conversation);
      }
    } on ServerException catch (e) {
      yield Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }

  @override
  Future<Result<void>> sendMessage({
    required String matchId,
    required String text,
  }) => _guard(() => remoteDataSource.sendMessage(matchId: matchId, text: text));

  @override
  Future<Result<Map<String, ChatMessage>>> getLastMessages(
    List<String> matchIds,
  ) => _guard(() => remoteDataSource.getLastMessages(matchIds));

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
