import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/chat_time.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../safety/presentation/widgets/safety_menu_button.dart';
import '../../domain/entities/daily_question.dart';
import '../../domain/entities/feed_post.dart';
import '../bloc/feed_cubit.dart';

/// "Günün sorusu": one prompt a day, one short answer per member, likes
/// only. Somewhere to go once the discovery feed runs out - it never opens
/// a conversation, so messaging stays match-only.
///
/// Laid out as a flat timeline (avatar on the left, hairline dividers, no
/// boxed cards) rather than the card style of the wizard screens, so many
/// answers read quickly - but on the same cream page and backdrop glows as
/// every other screen.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FeedCubit>()..start(),
      child: const _FeedView(),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final accepted = await context.read<FeedCubit>().submit(
      _answerController.text,
    );
    if (accepted && mounted) {
      _answerController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Günün Sorusu',
          style: textTheme.titleSmall?.copyWith(
            fontSize: 18,
            color: colors.plumStrong,
          ),
        ),
      ),
      body: WizardBackdrop(
        child: BlocConsumer<FeedCubit, FeedState>(
          listenWhen: (previous, current) =>
              current is FeedLoaded && current.actionError != null,
          listener: (context, state) {
            if (state is FeedLoaded && state.actionError != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.actionError!)));
            }
          },
          builder: (context, state) {
            switch (state) {
              case FeedLoading():
                return const Center(child: CircularProgressIndicator());
              case FeedError(:final message):
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(color: colors.rose),
                    ),
                  ),
                );
              case FeedLoaded(:final feed, :final isSubmitting):
                final mine = feed.mine;
                final others = feed.others;
                return ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _QuestionHeader(question: feed.question),
                    Divider(height: 1, color: colors.line),
                    if (mine == null)
                      _Composer(
                        controller: _answerController,
                        isSubmitting: isSubmitting,
                        onSubmit: _submit,
                      )
                    else
                      _PostRow(
                        post: mine,
                        onDelete: () => context.read<FeedCubit>().deleteMine(),
                      ),
                    _SectionBand(
                      label: others.isEmpty
                          ? 'Diğer cevaplar'
                          : 'Diğer cevaplar (${others.length})',
                    ),
                    if (others.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Text(
                          mine == null
                              ? 'Henüz kimse cevap vermedi. İlk cevabı sen yaz.'
                              : 'Şimdilik başka cevap yok. Yeni cevaplar geldikçe '
                                    'burada görünecek.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.inkSoft,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < others.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 72, color: colors.line),
                        _PostRow(post: others[i]),
                      ],
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

/// The day's prompt, centered: a "BUGÜN" label with the crescent beside
/// it and the question underneath.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final DailyQuestion question;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nightlight_round, size: 14, color: colors.teal),
              const SizedBox(width: 6),
              Text(
                'BUGÜN',
                style: textTheme.labelSmall?.copyWith(color: colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium?.copyWith(
              fontSize: 22,
              height: 1.3,
              color: colors.plumStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline "write your answer" row - an avatar-sized badge, a borderless
/// field and a small share pill, instead of a boxed form.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.brandGradient,
              ),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 6,
                  maxLength: DailyQuestion.maxAnswerLength,
                  textCapitalization: TextCapitalization.sentences,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Cevabını yaz…',
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: colors.inkSoft,
                    ),
                    filled: false,
                    isDense: true,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                Text(
                  'Adın, yaşın ve şehrinle tüm üyelere görünür. Günde bir cevap.',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkSoft),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final length = value.text.characters.length;
                    final hasText = value.text.trim().isNotEmpty;
                    return Row(
                      children: [
                        Text(
                          '$length/${DailyQuestion.maxAnswerLength}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        _SharePill(
                          enabled: hasText && !isSubmitting,
                          loading: isSubmitting,
                          onTap: onSubmit,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  const _SharePill({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final active = enabled || loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active ? null : colors.plumTint,
            gradient: active
                ? LinearGradient(colors: colors.brandGradient)
                : null,
          ),
          child: Center(
            widthFactor: 1,
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Paylaş',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      color: active ? Colors.white : colors.inkSoft,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A full-width band that separates "my side" (question + my answer) from
/// everybody else's answers, like the section breaks in a timeline.
class _SectionBand extends StatelessWidget {
  const _SectionBand({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      color: colors.plumTint.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: colors.plumStrong),
      ),
    );
  }
}

/// One answer as a timeline row. With [onDelete] set it is the current
/// user's own answer: tinted, labelled, deletable and not likeable.
class _PostRow extends StatelessWidget {
  const _PostRow({required this.post, this.onDelete});

  final FeedPost post;
  final VoidCallback? onDelete;

  bool get _mine => onDelete != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pair = AvatarPalette.forSeed(post.avatarColorSeed);
    final meta = _mine
        ? formatRelativeShort(post.createdAt)
        : '${post.authorCity} · ${formatRelativeShort(post.createdAt)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: pair,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              post.authorName.isEmpty ? '?' : post.authorName.characters.first,
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              flex: 3,
                              child: Text(
                                _mine
                                    ? 'Senin cevabın'
                                    : '${post.authorName}, ${post.authorAge}',
                                style: textTheme.titleSmall?.copyWith(
                                  color: _mine
                                      ? colors.plum
                                      : colors.plumStrong,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: Text(
                                meta,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.inkSoft,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_mine)
                        SafetyMenuButton(
                          key: ValueKey('menu_${post.id}'),
                          targetUserId: post.authorId,
                          targetName: post.authorName,
                          onBlocked: () => context.read<FeedCubit>().hideAuthor(
                            post.authorId,
                          ),
                          trigger: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              size: 22,
                              color: colors.inkSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    post.text,
                    style: textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(height: 2),
                if (_mine)
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount} beğeni',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.rose,
                        ),
                        child: const Text('Sil'),
                      ),
                    ],
                  )
                else
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: post.likedByMe
                              ? 'Beğeniyi geri al'
                              : 'Beğen',
                          onPressed: () =>
                              context.read<FeedCubit>().toggleLike(post),
                          icon: Icon(
                            post.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 21,
                            color: post.likedByMe
                                ? colors.accent
                                : colors.inkSoft,
                          ),
                        ),
                        Text(
                          '${post.likeCount}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: post.likedByMe
                                ? colors.accent
                                : colors.inkSoft,
                            fontWeight: post.likedByMe ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
