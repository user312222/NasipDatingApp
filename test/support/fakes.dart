import 'dart:async';
import 'dart:typed_data';

import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/candidate.dart';
import 'package:binasip/features/matching/domain/entities/candidate_filter.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/entities/swipe_outcome.dart';
import 'package:binasip/features/matching/domain/repositories/matching_repository.dart';
import 'package:binasip/features/messaging/domain/entities/chat_message.dart';
import 'package:binasip/features/messaging/domain/entities/conversation.dart';
import 'package:binasip/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:binasip/features/safety/domain/entities/report_reason.dart';
import 'package:binasip/features/safety/domain/repositories/safety_repository.dart';

/// Shared fakes for the screen tests. Streams are driven by hand through
/// the public controllers; events added before a listener subscribes are
/// buffered, so a test can seed data before pumping the widget.
class FakeMatchingRepository implements MatchingRepository {
  FakeMatchingRepository(this.result);

  final Result<List<Match>> result;

  @override
  Future<Result<List<Match>>> getMyMatches() async => result;

  @override
  Future<Result<List<Candidate>>> getCandidates(CandidateFilter filter) =>
      throw UnimplementedError();

  @override
  Future<Result<SwipeOutcome>> swipe({
    required Candidate candidate,
    required SwipeAction action,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) => throw UnimplementedError();
}

class FakeMessagingRepository implements MessagingRepository {
  final previews = StreamController<Result<Map<String, ChatMessage>>>();
  final readTimes = StreamController<Result<Map<String, DateTime>>>();
  final conversations = StreamController<Result<Conversation>>();

  /// Completes the in-flight [sendMessage]; null when nothing is sending.
  Completer<Result<void>>? pendingSend;
  final sentTexts = <String>[];
  final dismissedMatchIds = <String>[];
  final markedReadMatchIds = <String>[];

  @override
  Stream<Result<Map<String, ChatMessage>>> watchLastMessages(
    List<String> matchIds,
  ) => previews.stream;

  @override
  Stream<Result<Map<String, DateTime>>> watchReadTimes() => readTimes.stream;

  @override
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) => conversations.stream;

  @override
  Future<Result<void>> sendMessage({
    required String matchId,
    required String text,
  }) {
    sentTexts.add(text);
    final completer = Completer<Result<void>>();
    pendingSend = completer;
    return completer.future;
  }

  @override
  Future<Result<void>> markConversationRead(String matchId) async {
    markedReadMatchIds.add(matchId);
    return const Ok(null);
  }

  @override
  Future<Result<void>> dismissFamilyNudge(String matchId) async {
    dismissedMatchIds.add(matchId);
    return const Ok(null);
  }
}

class FakeSafetyRepository implements SafetyRepository {
  @override
  Future<Result<void>> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  }) async => const Ok(null);

  @override
  Future<Result<void>> blockUser(String targetUserId) async => const Ok(null);

  @override
  Future<Result<void>> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  }) async => const Ok(null);
}

Match testMatch(String id, DateTime matchedAt) => Match(
  id: id,
  matchedAt: matchedAt,
  candidate: Candidate(
    id: 'user_$id',
    name: 'Aday $id',
    age: 27,
    city: 'İstanbul',
    intent: CandidateIntent.marriage,
    avatarColorSeed: 1,
  ),
);

ChatMessage theirMessage(String text, DateTime sentAt) => ChatMessage(
  id: 'them_$text',
  text: text,
  sentAt: sentAt,
  sender: MessageSender.them,
);

ChatMessage myMessage(String text, DateTime sentAt) => ChatMessage(
  id: 'me_$text',
  text: text,
  sentAt: sentAt,
  sender: MessageSender.me,
);

Conversation testConversation(
  List<ChatMessage> messages, {
  bool familyNudgeShown = false,
}) => Conversation(
  matchId: 'm1',
  otherPartyName: 'Deniz',
  otherPartyAvatarSeed: 3,
  messages: messages,
  familyNudgeShown: familyNudgeShown,
);
