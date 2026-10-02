import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../../safety/presentation/widgets/safety_menu_button.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_cubit.dart';

/// Navigation payload for `context.push('/chat', extra: ChatRouteArgs(...))`
/// — go_router's `extra` is untyped `Object?`, this is the one place that
/// gives it a shape.
class ChatRouteArgs {
  const ChatRouteArgs({
    required this.matchId,
    required this.otherPartyUserId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String matchId;
  final String otherPartyUserId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;
}

/// Self-contained, like `DiscoveryScreen` — no cross-screen wizard state
/// to share, so `ChatCubit` is provided right here.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherPartyUserId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String matchId;
  final String otherPartyUserId;
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
      child: _ChatView(
        otherPartyUserId: otherPartyUserId,
        otherPartyName: otherPartyName,
        otherPartyAvatarSeed: otherPartyAvatarSeed,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({
    required this.otherPartyUserId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String otherPartyUserId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;

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
        if (state is! ChatLoaded) return;
        _scrollToBottom();
        if (state.sendError != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.sendError!)));
        }
      },
      builder: (context, state) {
        final title = state is ChatLoaded
            ? state.conversation.otherPartyName
            : widget.otherPartyName;
        final pair = AvatarPalette.forSeed(widget.otherPartyAvatarSeed);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                _Avatar(name: title, colors: pair, size: 38),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title.isEmpty ? 'Sohbet' : title,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.plumStrong,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              SafetyMenuButton(
                targetUserId: widget.otherPartyUserId,
                targetName: widget.otherPartyName,
                onBlocked: () => context.pop(),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          pair.first.withValues(alpha: 0.30),
                          pair.first.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              switch (state) {
                ChatLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ChatError(:final message) => Center(
                  child: Text(
                    message,
                    style: textTheme.bodyLarge?.copyWith(color: colors.rose),
                  ),
                ),
                ChatLoaded(:final conversation, :final isSending) => Column(
                  children: [
                    if (conversation.shouldShowFamilyNudge)
                      const _FamilyNudgeCard(),
                    Expanded(
                      child: conversation.messages.isEmpty
                          ? _EmptyChat(name: title, colors: pair)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: conversation.messages.length,
                              itemBuilder: (context, index) => _MessageBubble(
                                key: ValueKey(conversation.messages[index].id),
                                message: conversation.messages[index],
                              ),
                            ),
                    ),
                    _Composer(
                      controller: _textController,
                      isSending: isSending,
                    ),
                  ],
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

/// The gradient initial-letter circle used in place of a photo (photos stay
/// privacy-gated, see FR-3) — same look as the discovery card and the
/// matches list.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.colors, required this.size});

  final String name;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.name, required this.colors});

  final String name;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final appColors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(name: name, colors: colors, size: 84),
            const SizedBox(height: 18),
            Text(
              '$name ile eşleştin.',
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                color: appColors.plumStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'İlk mesajı sen yaz — nazik bir merhaba yeter.',
              style: textTheme.bodyMedium?.copyWith(color: appColors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isMe = message.sender == MessageSender.me;
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.plumFill, const Color(0xFF9C4590)],
                  )
                : null,
            color: isMe ? null : colors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMe ? 22 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 22),
            ),
            border: isMe ? null : Border.all(color: colors.line),
            boxShadow: [
              BoxShadow(
                color: colors.plumStrong.withValues(alpha: isMe ? 0.18 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: isMe ? Colors.white : colors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : colors.inkSoft,
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              // Enter sends, Shift+Enter inserts a newline — for hardware
              // keyboards (web/desktop); soft keyboards keep their own
              // newline key since the field is multiline.
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    if (!isSending) _send(context);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Bir mesaj yaz…',
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: colors.plum, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _send(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedOpacity(
              opacity: isSending ? 0.5 : 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.plumFill, const Color(0xFFC17B72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.plumFill.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isSending ? null : () => _send(context),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: colors.brassTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.brass.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.brass.withValues(alpha: 0.22),
            ),
            child: Icon(Icons.favorite_rounded, color: colors.brass, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bir sonraki adımı düşünmek ister misin?',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'İstersen aileni sürece dahil etmeyi ya da bir buluşma ayarlamayı '
                  'değerlendirebilirsin. Tamamen sana kalmış.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.push('/family/settings'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.plumStrong,
                    ),
                    child: const Text('Aileni sürece dahil et'),
                  ),
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
