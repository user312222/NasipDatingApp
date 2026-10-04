import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// The per-match "aileme göster" switch (FR-8.4) with its one-line
/// explanation — shared by the match celebration and the chat. Purely
/// presentational: the host owns the value and what saving means.
class ShowFamilySwitchRow extends StatelessWidget {
  const ShowFamilySwitchRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.failed = false,
    this.caption = 'Bağlı yakının bu eşleşmeyi görür; mesajları göremez.',
  });

  final bool value;

  /// Null while a change is being saved, which locks the switch.
  final ValueChanged<bool>? onChanged;

  /// The last change could not be saved; replaces [caption] with a notice.
  final bool failed;

  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: value ? colors.plumTint : colors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: value ? colors.plum : colors.line),
      ),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aileme göster',
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.plumStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    failed ? 'Kaydedilemedi, tekrar dene.' : caption,
                    style: textTheme.bodySmall?.copyWith(
                      color: failed ? colors.rose : colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: colors.plumFill,
            ),
          ],
        ),
      ),
    );
  }
}
