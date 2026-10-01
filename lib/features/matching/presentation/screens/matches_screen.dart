import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/chat_time.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../theme/app_colors.dart';
import '../../../messaging/domain/entities/chat_message.dart';
import '../../../messaging/presentation/screens/chat_screen.dart';
import '../../domain/entities/match.dart';
import '../bloc/matches_cubit.dart';
import '../../../../theme/avatar_palette.dart';

/// Every mutual match, newest first — the way back into a conversation
/// once the match celebration has been dismissed.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MatchesCubit>()..load(),
      child: const _MatchesView(),
    );
  }
}

class _MatchesView extends StatelessWidget {
  const _MatchesView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final prefs = sl<AppPreferences>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eşleşmeler',
          style: textTheme.displayMedium?.copyWith(
            fontSize: 26,
            color: colors.plumStrong,
          ),
        ),
      ),
      body: BlocBuilder<MatchesCubit, MatchesState>(
        builder: (context, state) {
          switch (state) {
            case MatchesLoading():
              return const Center(child: CircularProgressIndicator());
            case MatchesError(:final message):
              return Center(
                child: Text(
                  message,
                  style: textTheme.bodyLarge?.copyWith(color: colors.rose),
                ),
              );
            case MatchesLoaded(:final matches, :final previews):
              if (matches.isEmpty) return const _EmptyMatches();
              return ValueListenableBuilder<bool>(
                valueListenable: prefs.showMatchMessagePreviews,
                builder: (context, showPreviews, _) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _MatchTile(
                    match: matches[i],
                    preview: previews[matches[i].id],
                    showPreview: showPreviews,
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.plumTint,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 32,
                color: colors.plum,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz eşleşmen yok.',
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Karşılıklı beğendiğin kişiler burada görünecek.',
              style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    this.preview,
    required this.showPreview,
  });

  final Match match;
  final ChatMessage? preview;

  /// The "Eşleşmeler listesinde mesaj önizlemesi" setting — when off, this
  /// row never renders message text or activity timestamps, only the
  /// candidate's own profile info (city). Unrelated to, and never as
  /// permissive as, what a linked guardian can see (FR-8.5 never shows
  /// message content there regardless of this setting).
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final candidate = match.candidate;
    final pair = AvatarPalette.forSeed(candidate.avatarColorSeed);
    final showMessageRow = showPreview && preview != null;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          final cubit = context.read<MatchesCubit>();
          await context.push(
            '/chat',
            extra: ChatRouteArgs(
              matchId: match.id,
              otherPartyUserId: candidate.id,
              otherPartyName: candidate.name,
              otherPartyAvatarSeed: candidate.avatarColorSeed,
            ),
          );
          cubit.refreshPreviews();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
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
                  candidate.name.characters.first,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${candidate.name}, ${candidate.age}',
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.plumStrong,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showMessageRow) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatChatTimestamp(preview!.sentAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.inkSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (showMessageRow)
                      Text(
                        preview!.sender == MessageSender.me
                            ? 'Sen: ${preview!.text}'
                            : preview!.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: preview!.sender == MessageSender.me
                              ? colors.inkSoft
                              : colors.ink,
                        ),
                      )
                    else if (!showPreview)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: colors.rose,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              candidate.city,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.inkSoft,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'İlk mesajı sen yaz',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.brass,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (!showMessageRow) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.plumTint,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: colors.plumStrong,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
