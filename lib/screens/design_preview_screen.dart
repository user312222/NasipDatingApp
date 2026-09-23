import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary screen for visually checking the design system (colors +
/// type scale) against the Figma "🎨 Foundations" page. Not a product
/// screen — safe to delete once real screens exist.
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bi Nasip — Tasarım Önizleme')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Renkler', style: textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Swatch('bg', colors.bg),
              _Swatch('surface', colors.surface),
              _Swatch('ink', colors.ink),
              _Swatch('ink-soft', colors.inkSoft),
              _Swatch('plum', colors.plum),
              _Swatch('plum-strong', colors.plumStrong),
              _Swatch('plum-tint', colors.plumTint),
              _Swatch('brass', colors.brass),
              _Swatch('brass-tint', colors.brassTint),
              _Swatch('rose', colors.rose),
              _Swatch('rose-soft', colors.roseSoft),
              _Swatch('line', colors.line),
            ],
          ),
          const SizedBox(height: 32),
          Text('Tipografi', style: textTheme.titleSmall),
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Bana da nasip olsun'),
          ),
        ],
      ),
    );
  }
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
