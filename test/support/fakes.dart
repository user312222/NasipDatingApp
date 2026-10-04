import 'dart:async';
import 'dart:typed_data';

import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/feed/domain/entities/daily_question.dart';
import 'package:binasip/features/feed/domain/entities/feed.dart';
import 'package:binasip/features/feed/domain/entities/feed_post.dart';
import 'package:binasip/features/feed/domain/repositories/feed_repository.dart';
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

  /// Mutable so a test can change what the next `getMyMatches` returns.
  Result<List<Match>> result;

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

  /// What the next [setMatchVisibleToFamily] call returns.
  Result<void> familyVisibleResult = const Ok(null);

  /// Every (matchId, visible) pair [setMatchVisibleToFamily] was asked for.
  final familyVisibleCalls = <({String matchId, bool visible})>[];

  @override
  Future<Result<void>> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) async {
    familyVisibleCalls.add((matchId: matchId, visible: visible));
    return familyVisibleResult;
  }
}

class FakeMessagingRepository implements MessagingRepository {
  /// Optionally seeds the first previews emission, like a Firestore
  /// listener that reports right after subscribing.
  FakeMessagingRepository([Result<Map<String, ChatMessage>>? firstPreviews]) {
    if (firstPreviews != null) previews.add(firstPreviews);
  }

  /// One controller per [watchLastMessages] call (a resubscribe gets a
  /// fresh one); [previews] is the latest, created on first read so a test
  /// can seed data before anything subscribes.
  final previewStreams = <StreamController<Result<Map<String, ChatMessage>>>>[];
  var _lastPreviewsHandedOut = false;

  StreamController<Result<Map<String, ChatMessage>>> get previews =>
      previewStreams.isEmpty ? _newPreviews() : previewStreams.last;

  StreamController<Result<Map<String, ChatMessage>>> _newPreviews() {
    final controller = StreamController<Result<Map<String, ChatMessage>>>();
    previewStreams.add(controller);
    _lastPreviewsHandedOut = false;
    return controller;
  }

  final readTimes = StreamController<Result<Map<String, DateTime>>>();

  /// The ids [watchLastMessages] was last asked about; null if never.
  List<String>? lastRequestedIds;

  /// One controller per [watchConversation] call (a re-open gets a fresh
  /// one). [conversations] is the latest; reading it before the first call
  /// creates it, so a test can seed data before the screen subscribes.
  final conversationStreams = <StreamController<Result<Conversation>>>[];
  var _lastConversationHandedOut = false;

  StreamController<Result<Conversation>> get conversations =>
      conversationStreams.isEmpty
      ? _newConversation()
      : conversationStreams.last;

  StreamController<Result<Conversation>> _newConversation() {
    final controller = StreamController<Result<Conversation>>();
    conversationStreams.add(controller);
    _lastConversationHandedOut = false;
    return controller;
  }

  /// Completes the in-flight [sendMessage]; null when nothing is sending.
  Completer<Result<void>>? pendingSend;
  final sentTexts = <String>[];
  final dismissedMatchIds = <String>[];
  final markedReadMatchIds = <String>[];

  @override
  Stream<Result<Map<String, ChatMessage>>> watchLastMessages(
    List<String> matchIds,
  ) {
    lastRequestedIds = matchIds;
    final controller = previewStreams.isEmpty || _lastPreviewsHandedOut
        ? _newPreviews()
        : previewStreams.last;
    _lastPreviewsHandedOut = true;
    return controller.stream;
  }

  @override
  Stream<Result<Map<String, DateTime>>> watchReadTimes() => readTimes.stream;

  @override
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) {
    final controller = conversationStreams.isEmpty || _lastConversationHandedOut
        ? _newConversation()
        : conversationStreams.last;
    _lastConversationHandedOut = true;
    return controller.stream;
  }

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

class FakeFeedRepository implements FeedRepository {
  final feeds = StreamController<Result<Feed>>();

  /// Completes the in-flight [submitAnswer]; null when nothing is pending.
  Completer<Result<void>>? pendingSubmit;
  final submitted = <String>[];
  final likeCalls = <({String postId, bool liked})>[];
  var deleteCalls = 0;
  Result<void> likeResult = const Ok(null);
  Result<void> deleteResult = const Ok(null);

  @override
  Stream<Result<Feed>> watchToday() => feeds.stream;

  @override
  Future<Result<void>> submitAnswer(String text) {
    submitted.add(text);
    final completer = Completer<Result<void>>();
    pendingSubmit = completer;
    return completer.future;
  }

  @override
  Future<Result<void>> deleteMyAnswer() async {
    deleteCalls++;
    return deleteResult;
  }

  @override
  Future<Result<void>> setLiked({
    required String postId,
    required bool liked,
  }) async {
    likeCalls.add((postId: postId, liked: liked));
    return likeResult;
  }
}

const testQuestion = DailyQuestion(
  dayKey: '2026-3-6',
  text: 'İdeal bir pazar günün nasıl geçer?',
);

FeedPost testPost(
  String author, {
  String? text,
  bool isMine = false,
  bool likedByMe = false,
  int likeCount = 0,
  DateTime? createdAt,
}) => FeedPost(
  id: '${author}_2026-3-6',
  authorId: author,
  authorName: 'Üye $author',
  authorAge: 28,
  authorCity: 'Ankara',
  avatarColorSeed: 2,
  text: text ?? 'cevap $author',
  createdAt: createdAt ?? DateTime(2026, 3, 6, 10),
  likeCount: likeCount,
  likedByMe: likedByMe,
  isMine: isMine,
);

Feed testFeed(List<FeedPost> posts) =>
    Feed(question: testQuestion, posts: posts);
