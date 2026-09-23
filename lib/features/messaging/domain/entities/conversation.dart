import 'package:equatable/equatable.dart';

import 'chat_message.dart';

/// One FR-4.2 match's chat thread. `otherPartyName`/`otherPartyAvatarSeed`
/// are denormalized display fields — this feature deliberately doesn't
/// import `matching`'s `Candidate` entity (same reasoning as `matching`
/// not importing `profile`'s `ProfileIntent`); the screen that opens a
/// conversation is the one place that bridges the two features.
class Conversation extends Equatable {
  const Conversation({
    required this.matchId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
    required this.messages,
    this.familyNudgeShown = false,
  });

  final String matchId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;
  final List<ChatMessage> messages;

  /// FR-5.2: whether the one-time nudge has already been shown for this
  /// conversation — once true, it never shows again here.
  final bool familyNudgeShown;

  DateTime? get firstMessageAt =>
      messages.isEmpty ? null : messages.first.sentAt;

  /// FR-5.2: 30 total messages OR 7 days of active conversation,
  /// whichever comes first — and only if not already shown.
  bool get shouldShowFamilyNudge {
    if (familyNudgeShown) return false;
    if (messages.length >= 30) return true;
    final first = firstMessageAt;
    if (first == null) return false;
    return DateTime.now().difference(first).inDays >= 7;
  }

  Conversation copyWith({
    List<ChatMessage>? messages,
    bool? familyNudgeShown,
  }) => Conversation(
    matchId: matchId,
    otherPartyName: otherPartyName,
    otherPartyAvatarSeed: otherPartyAvatarSeed,
    messages: messages ?? this.messages,
    familyNudgeShown: familyNudgeShown ?? this.familyNudgeShown,
  );

  @override
  List<Object?> get props => [
    matchId,
    otherPartyName,
    otherPartyAvatarSeed,
    messages,
    familyNudgeShown,
  ];
}
