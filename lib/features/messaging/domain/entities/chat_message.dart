import 'package:equatable/equatable.dart';

enum MessageSender { me, them }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.sender,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final MessageSender sender;

  @override
  List<Object?> get props => [id, text, sentAt, sender];
}
