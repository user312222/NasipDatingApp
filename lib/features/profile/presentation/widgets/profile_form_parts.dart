import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';

/// The pieces of the profile form that the registration wizard and the
/// "Profili düzenle" screen both show, kept in one place so the choices and
/// their wording cannot drift apart between the two.

/// FR-2.2: the two intents - and only these two.
class IntentOptions extends StatelessWidget {
  const IntentOptions({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProfileIntent? selected;
  final ValueChanged<ProfileIntent> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionCard(
          icon: Icons.diamond_outlined,
          title: 'Evlilik',
          subtitle: 'Ciddi, evliliğe yönelik bir ilişki arıyorum.',
          selected: selected == ProfileIntent.marriage,
          onTap: () => onChanged(ProfileIntent.marriage),
        ),
        const SizedBox(height: 12),
        OptionCard(
          icon: Icons.hourglass_empty_rounded,
          title: 'Henüz emin değilim',
          subtitle: 'Süreç içinde netleşsin istiyorum.',
          selected: selected == ProfileIntent.notSureYet,
          onTap: () => onChanged(ProfileIntent.notSureYet),
        ),
      ],
    );
  }
}

/// FR-3.1: the three photo-reveal levels, most restrictive first.
class PhotoVisibilityOptions extends StatelessWidget {
  const PhotoVisibilityOptions({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PhotoVisibility selected;
  final ValueChanged<PhotoVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OptionCard(
          icon: Icons.visibility_off_outlined,
          title: 'Ben açana kadar gizli',
          subtitle: 'Kimseye otomatik ya da istek üzerine açılmaz. Varsayılan ve en kısıtlı seçenek.',
          selected: selected == PhotoVisibility.hiddenUntilIUnlock,
          onTap: () => onChanged(PhotoVisibility.hiddenUntilIUnlock),
        ),
        const SizedBox(height: 12),
        OptionCard(
          icon: Icons.mark_email_unread_outlined,
          title: 'Sadece istek üzerine',
          subtitle: 'Biri istediğinde bildirim alırsın, onaylarsan görünür.',
          selected: selected == PhotoVisibility.onRequestOnly,
          onTap: () => onChanged(PhotoVisibility.onRequestOnly),
        ),
        const SizedBox(height: 12),
        OptionCard(
          icon: Icons.favorite_border_rounded,
          title: 'Eşleşince otomatik',
          subtitle: 'Karşılıklı eşleşme oluşunca otomatik açılır.',
          selected: selected == PhotoVisibility.autoOnMatch,
          onTap: () => onChanged(PhotoVisibility.autoOnMatch),
        ),
      ],
    );
  }
}

/// Quick picks for the madhhab field (FR-2.3). The field itself stays free
/// text; the last chip is the non-answer [madhhabNoAnswer].
class MadhhabSuggestions extends StatelessWidget {
  const MadhhabSuggestions({super.key, required this.onSelected});

  static const _suggestions = ['Sünni', 'Caferi', 'Alevi', madhhabNoAnswer];

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final suggestion in _suggestions)
          ActionChip(
            label: Text(suggestion),
            onPressed: () => onSelected(suggestion),
            backgroundColor: colors.plumTint,
            labelStyle: textTheme.bodyMedium?.copyWith(
              color: colors.plumStrong,
            ),
            side: BorderSide.none,
          ),
      ],
    );
  }
}

/// KVKK m.6: din bilgisi özel nitelikli veridir ve ayrı bir açık rıza
/// gerektirir. Shown only while the form holds such data that has not been
/// consented to yet; the form may not be saved until the box is ticked.
class SensitiveDataConsentCard extends StatelessWidget {
  const SensitiveDataConsentCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.plumTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Din/mezhep bilgisi, KVKK’ya göre özel nitelikli '
            'veridir ve ayrı bir açık rıza gerektirir.',
            style: textTheme.bodyMedium?.copyWith(color: colors.plumStrong),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Yukarıda yazdığım dini pratik/mezhep '
                      'bilgisinin işlenmesini açıkça kabul '
                      'ediyorum.',
                      style: textTheme.bodyMedium,
                    ),
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
