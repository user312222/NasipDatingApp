import 'package:flutter/material.dart';

import '../features/family/domain/entities/family_visible_match.dart';
import '../features/family/presentation/screens/guardian_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/avatar_palette.dart';
import '../theme/wizard_widgets.dart';

/// Developer gallery of the design system — palette, type scale and the
/// shared widgets from `wizard_widgets.dart` — with a local light/dark
/// switch, so both themes can be checked without changing the device
/// setting. Not a product screen (reachable at `/design-preview`).
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  bool? _dark;
  int _option = 0;
  bool _chip = true;

  @override
  Widget build(BuildContext context) {
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final dark = _dark ?? systemDark;

    return Theme(
      data: dark ? AppTheme.dark() : AppTheme.light(),
      child: Builder(builder: (context) => _body(context, dark)),
    );
  }

  Widget _body(BuildContext context, bool dark) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasarım Önizleme'),
        actions: [
          Icon(
            dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 20,
            color: colors.plumStrong,
          ),
          Switch(value: dark, onChanged: (v) => setState(() => _dark = v)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(textTheme, 'Renkler'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Swatch('bg', colors.bg),
              _Swatch('surface', colors.surface),
              _Swatch('ink', colors.ink),
              _Swatch('ink-soft', colors.inkSoft),
              _Swatch('plum', colors.plum),
              _Swatch('plum-fill', colors.plumFill),
              _Swatch('plum-strong', colors.plumStrong),
              _Swatch('plum-tint', colors.plumTint),
              _Swatch('brass', colors.brass),
              _Swatch('brass-tint', colors.brassTint),
              _Swatch('rose', colors.rose),
              _Swatch('rose-soft', colors.roseSoft),
              _Swatch('line', colors.line),
            ],
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Avatar paletleri'),
          Row(
            children: [
              for (var seed = 0; seed < 4; seed++) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AvatarPalette.forSeed(seed),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ABCD'[seed],
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Tipografi'),
          Text('Herkesin bi nasibi var.', style: textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Bu boşluk Türkiye’de hâlâ dolmadı.',
            style: textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text('Bekleme listesine katıl', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Niyet baştan belli.', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Evliliği hedefleyen, mahremiyetini kendi elinde tutmak isteyenler için.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk 500 kişiye ömür boyu üyelik ayrıcalığı tanınacak.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text('TÜRKİYE’DE YAKINDA', style: textTheme.labelSmall),
          const SizedBox(height: 8),
          Text(
            'نصيب',
            style: AppTextStyles.accentArabic.copyWith(color: colors.plum),
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Butonlar'),
          GradientButton(label: 'Devam et', onPressed: () {}),
          const SizedBox(height: 10),
          const GradientButton(label: 'Devre dışı', onPressed: null),
          const SizedBox(height: 10),
          GradientButton(label: 'Yükleniyor', loading: true, onPressed: () {}),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: const Text('ElevatedButton')),
          const SizedBox(height: 28),
          _section(textTheme, 'Sihirbaz başlığı'),
          const WizardHeader(
            icon: Icons.lock_rounded,
            title: 'Başlık burada.',
            subtitle: 'Altındaki açıklama metni iki satıra kadar uzayabilir.',
            step: 2,
            totalSteps: 5,
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Seçenek kartları'),
          for (var i = 0; i < 3; i++) ...[
            OptionCard(
              icon: [
                Icons.visibility_off_outlined,
                Icons.mark_email_unread_outlined,
                Icons.favorite_border_rounded,
              ][i],
              title: ['Gizli', 'İstek üzerine', 'Eşleşince'][i],
              subtitle: 'Seçenek $i için kısa bir açıklama.',
              selected: _option == i,
              onTap: () => setState(() => _option = i),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          _section(textTheme, 'Bölüm kartları'),
          const SectionCard(
            icon: Icons.verified_user_rounded,
            title: 'Normal kart',
            body: 'Gruplanmış ayar bölümleri için ikon rozetli kart.',
          ),
          const SizedBox(height: 10),
          const SectionCard(
            icon: Icons.delete_outline_rounded,
            title: 'Tehlikeli bölge',
            body: 'Geri alınamayan işlemler rose tonuyla ayrışır.',
            danger: true,
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Yakın eşleşme kartı'),
          VisibleMatchCard(
            match: FamilyVisibleMatch(
              candidateName: 'Zeynep',
              candidateAge: 27,
              candidateCity: 'İstanbul',
              statusLabel: 'Yeni eşleşme',
              matchedAt: DateTime(2026, 9, 1),
            ),
          ),
          const SizedBox(height: 10),
          VisibleMatchCard(
            match: FamilyVisibleMatch(
              candidateName: 'Elif Nur',
              candidateAge: 31,
              candidateCity: 'Eskişehir',
              statusLabel: 'Aktif yazışıyorlar',
              matchedAt: DateTime(2026, 8, 20),
            ),
          ),
          const SizedBox(height: 28),
          _section(textTheme, 'Çipler ve mesajlar'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Seçili'),
                selected: _chip,
                onSelected: (_) => setState(() => _chip = true),
              ),
              ChoiceChip(
                label: const Text('Seçili değil'),
                selected: !_chip,
                onSelected: (_) => setState(() => _chip = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Snackbar örneği.'))),
            child: const Text('Snackbar göster'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(TextTheme textTheme, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: textTheme.titleSmall),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 84,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
