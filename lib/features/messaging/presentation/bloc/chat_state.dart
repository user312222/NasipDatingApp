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
  const ChatLoaded(this.conversation, {this.isSending = false, this.sendError});

  final Conversation conversation;
  final bool isSending;

  /// One-shot, like `MatchingLoaded.swipeError` — shown once on a
  /// `BlocListener` SnackBar, then naturally cleared by the next emission
  /// (the live stream's own updates never pass it along).
  final String? sendError;

  @override
  List<Object?> get props => [conversation, isSending, sendError];
}
