import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_cubit.dart';

/// Navigation payload for `context.push('/chat', extra: ChatRouteArgs(...))`
/// — go_router's `extra` is untyped `Object?`, this is the one place that
/// gives it a shape.
class ChatRouteArgs {
  const ChatRouteArgs({
    required this.matchId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String matchId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;
}

/// Self-contained, like `DiscoveryScreen` — no cross-screen wizard state
/// to share, so `ChatCubit` is provided right here.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String matchId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatCubit>()
        ..open(
          matchId: matchId,
          otherPartyName: otherPartyName,
          otherPartyAvatarSeed: otherPartyAvatarSeed,
        ),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        final title = state is ChatLoaded ? state.conversation.otherPartyName : '';
        return Scaffold(
          appBar: AppBar(title: Text(title.isEmpty ? 'Sohbet' : title)),
          body: switch (state) {
            ChatLoading() => const Center(child: CircularProgressIndicator()),
            ChatError(:final message) => Center(
              child: Text(message, style: textTheme.bodyLarge?.copyWith(color: colors.rose)),
            ),
            ChatLoaded(:final conversation, :final isSending) => Column(
              children: [
                if (conversation.shouldShowFamilyNudge) const _FamilyNudgeCard(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: conversation.messages[index]),
                  ),
                ),
                _Composer(controller: _textController, isSending: isSending),
              ],
            ),
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isMe = message.sender == MessageSender.me;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colors.plum : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
          border: isMe ? null : Border.all(color: colors.line),
        ),
        child: Text(
          message.text,
          style: textTheme.bodyLarge?.copyWith(color: isMe ? colors.bg : colors.ink),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.isSending});
  final TextEditingController controller;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Bir mesaj yaz…'),
                onSubmitted: (_) => _send(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : () => _send(context),
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: colors.plum, foregroundColor: colors.bg),
            ),
          ],
        ),
      ),
    );
  }

  void _send(BuildContext context) {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().send(text);
    controller.clear();
  }
}

class _FamilyNudgeCard extends StatelessWidget {
  const _FamilyNudgeCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.brassTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.brass.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, color: colors.brass, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bir sonraki adımı düşünmek ister misin?', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'İstersen aileni sürece dahil etmeyi ya da bir buluşma ayarlamayı '
                  'değerlendirebilirsin. Tamamen sana kalmış.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context.read<ChatCubit>().dismissFamilyNudge(),
            visualDensity: VisualDensity.compact,
            color: colors.inkSoft,
          ),
        ],
      ),
    );
  }
}
