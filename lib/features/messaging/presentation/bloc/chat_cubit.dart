import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/dismiss_family_nudge.dart';
import '../../domain/usecases/open_conversation.dart';
import '../../domain/usecases/send_message.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required OpenConversation openConversation,
    required SendMessage sendMessage,
    required DismissFamilyNudge dismissFamilyNudge,
  }) : _openConversation = openConversation,
       _sendMessage = sendMessage,
       _dismissFamilyNudge = dismissFamilyNudge,
       super(const ChatLoading());

  final OpenConversation _openConversation;
  final SendMessage _sendMessage;
  final DismissFamilyNudge _dismissFamilyNudge;

  Future<void> open({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) async {
    emit(const ChatLoading());
    final result = await _openConversation(
      OpenConversationParams(
        matchId: matchId,
        otherPartyName: otherPartyName,
        otherPartyAvatarSeed: otherPartyAvatarSeed,
      ),
    );
    switch (result) {
      case Ok<Conversation>(:final value):
        emit(ChatLoaded(value));
      case Err<Conversation>(:final failure):
        emit(ChatError(failure.message));
    }
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
    switch (result) {
      case Ok<Conversation>(:final value):
        emit(ChatLoaded(value));
      case Err<Conversation>(:final failure):
        emit(ChatError(failure.message));
    }
  }

  /// FR-5.2: called once the user dismisses the nudge card — persists so
  /// it never shows again for this conversation.
  Future<void> dismissFamilyNudge() async {
    final current = state;
    if (current is! ChatLoaded) return;
    emit(ChatLoaded(current.conversation.copyWith(familyNudgeShown: true)));
    await _dismissFamilyNudge(current.conversation.matchId);
  }
}
