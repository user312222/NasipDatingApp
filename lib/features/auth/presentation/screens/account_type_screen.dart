import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/account_type.dart';
import '../bloc/auth_cubit.dart';

/// FR-8.1. First screen after the invite gate — the choice is permanent
/// for the account, so there's no "change later" affordance here.
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  AccountType? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('Buraya neden geldin?', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Bu seçim hesabının türünü belirler ve sonradan değiştirilemez.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 24),
              _Card(
                title: 'Kendim için bakıyorum',
                subtitle: 'Evlilik niyetiyle birini tanımak istiyorum.',
                selected: _selected == AccountType.single,
                onTap: () => setState(() => _selected = AccountType.single),
              ),
              const SizedBox(height: 12),
              _Card(
                title: 'Bir yakınımın sürecini takip ediyorum',
                subtitle:
                    'Ben zaten evliyim; çocuğumun/yakınımın izin verdiği eşleşmeleri '
                    'görmek istiyorum. Kendim için kimseyle eşleşmiyorum.',
                selected: _selected == AccountType.guardian,
                onTap: () => setState(() => _selected = AccountType.guardian),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () {
                        context.read<AuthCubit>().selectAccountType(_selected!);
                        context.push('/phone');
                      },
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? colors.plumTint : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.plum : colors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? colors.plum : colors.inkSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
