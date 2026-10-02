import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/dismiss_family_nudge.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_conversation.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required WatchConversation watchConversation,
    required SendMessage sendMessage,
    required DismissFamilyNudge dismissFamilyNudge,
  }) : _watchConversation = watchConversation,
       _sendMessage = sendMessage,
       _dismissFamilyNudge = dismissFamilyNudge,
       super(const ChatLoading());

  final WatchConversation _watchConversation;
  final SendMessage _sendMessage;
  final DismissFamilyNudge _dismissFamilyNudge;
  StreamSubscription<Result<Conversation>>? _subscription;

  void open({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) {
    emit(const ChatLoading());
    unawaited(_subscription?.cancel());
    _subscription =
        _watchConversation(
          WatchConversationParams(
            matchId: matchId,
            otherPartyName: otherPartyName,
            otherPartyAvatarSeed: otherPartyAvatarSeed,
          ),
        ).listen((result) {
          switch (result) {
            case Ok<Conversation>(:final value):
              emit(ChatLoaded(value));
            case Err<Conversation>(:final failure):
              emit(ChatError(failure.message));
          }
        });
  }

  Future<void> send(String text) async {
    final current = state;
    if (current is! ChatLoaded || text.trim().isEmpty) return;

    emit(ChatLoaded(current.conversation, isSending: true));
    final result = await _sendMessage(
      SendMessageParams(
        matchId: current.conversation.matchId,
        text: text.trim(),
      ),
    );
    // The live stream may already have delivered the new message and
    // moved `state` on while this awaited — read it fresh rather than
    // reusing `current`.
    final latest = state;
    if (latest is! ChatLoaded) return;
    switch (result) {
      case Ok<void>():
        emit(ChatLoaded(latest.conversation));
      case Err<void>(:final failure):
        emit(ChatLoaded(latest.conversation, sendError: failure.message));
    }
  }

  /// FR-5.2: called once the user dismisses the nudge card — persists so
  /// it never shows again for this conversation. Emits optimistically;
  /// the live stream confirms it once Firestore round-trips.
  Future<void> dismissFamilyNudge() async {
    final current = state;
    if (current is! ChatLoaded) return;
    emit(
      ChatLoaded(
        current.conversation.copyWith(familyNudgeShown: true),
        isSending: current.isSending,
      ),
    );
    await _dismissFamilyNudge(current.conversation.matchId);
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
