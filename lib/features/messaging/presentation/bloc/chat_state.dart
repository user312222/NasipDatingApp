part of 'chat_cubit.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

final class ChatLoading extends ChatState {
  const ChatLoading();
}

final class ChatError extends ChatState {
  const ChatError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ChatLoaded extends ChatState {
  const ChatLoaded(this.conversation, {this.isSending = false});

  final Conversation conversation;
  final bool isSending;

  @override
  List<Object?> get props => [conversation, isSending];
}
