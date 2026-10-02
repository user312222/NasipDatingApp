import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
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
          style: textTheme.displayMedium?.copyWith(
            fontSize: 28,
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _QuestionCard(question: feed.question),
                    const SizedBox(height: 16),
                    if (mine == null)
                      _AnswerComposer(
                        controller: _answerController,
                        isSubmitting: isSubmitting,
                        onSubmit: _submit,
                      )
                    else
                      _MyAnswerCard(
                        post: mine,
                        onDelete: () => context.read<FeedCubit>().deleteMine(),
                      ),
                    const SizedBox(height: 26),
                    Text(
                      others.isEmpty
                          ? 'Diğer cevaplar'
                          : 'Diğer cevaplar (${others.length})',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.plumStrong,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (others.isEmpty)
                      Text(
                        mine == null
                            ? 'Henüz kimse cevap vermedi. İlk cevabı sen yaz.'
                            : 'Şimdilik başka cevap yok. Yeni cevaplar geldikçe '
                                  'burada görünecek.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.inkSoft,
                        ),
                      )
                    else
                      for (final post in others) ...[
                        _PostCard(post: post),
                        const SizedBox(height: 12),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final DailyQuestion question;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.teal, colors.plumFill],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.plumFill.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'BUGÜN',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: textTheme.displayMedium?.copyWith(
              fontSize: 25,
              height: 1.25,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerComposer extends StatelessWidget {
  const _AnswerComposer({
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              maxLength: DailyQuestion.maxAnswerLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Cevabını yaz…'),
            ),
            const SizedBox(height: 4),
            Text(
              'Cevabın adın, yaşın ve şehrinle birlikte tüm üyelere görünür. '
              'Günde bir cevap paylaşabilirsin.',
              style: textTheme.bodySmall?.copyWith(color: colors.inkSoft),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Paylaş',
              loading: isSubmitting,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyAnswerCard extends StatelessWidget {
  const _MyAnswerCard({required this.post, required this.onDelete});

  final FeedPost post;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: BoxDecoration(
        color: colors.plumTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.plum.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SENİN CEVABIN',
            style: textTheme.labelSmall?.copyWith(color: colors.plum),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(post.text, style: textTheme.bodyLarge),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                '${post.likeCount} beğeni',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const Spacer(),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: colors.rose),
                child: const Text('Sil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pair = AvatarPalette.forSeed(post.avatarColorSeed);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.plumFill.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  post.authorName.isEmpty
                      ? '?'
                      : post.authorName.characters.first,
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
                    Text(
                      '${post.authorName}, ${post.authorAge}',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.plumStrong,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: colors.teal,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            post.authorCity,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.inkSoft,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafetyMenuButton(
                key: ValueKey('menu_${post.id}'),
                targetUserId: post.authorId,
                targetName: post.authorName,
                onBlocked: () =>
                    context.read<FeedCubit>().hideAuthor(post.authorId),
              ),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(post.text, style: textTheme.bodyLarge),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              IconButton(
                tooltip: post.likedByMe ? 'Beğeniyi geri al' : 'Beğen',
                onPressed: () => context.read<FeedCubit>().toggleLike(post),
                icon: Icon(
                  post.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.likedByMe ? colors.accent : colors.inkSoft,
                ),
              ),
              Text(
                '${post.likeCount}',
                style: textTheme.bodyMedium?.copyWith(
                  color: post.likedByMe ? colors.accent : colors.inkSoft,
                  fontWeight: post.likedByMe ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
