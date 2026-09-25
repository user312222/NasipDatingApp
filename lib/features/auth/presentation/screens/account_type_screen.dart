import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
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
    return Scaffold(
      body: WizardBackdrop(
        child: WizardBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const WizardHeader(
                icon: Icons.explore_rounded,
                title: 'Buraya neden geldin?',
                subtitle: 'Bu seçim hesabının türünü belirler ve sonradan değiştirilemez.',
                step: 1,
                totalSteps: 5,
              ),
              const SizedBox(height: 26),
              OptionCard(
                icon: Icons.favorite_border_rounded,
                title: 'Kendim için bakıyorum',
                subtitle: 'Evlilik niyetiyle birini tanımak istiyorum.',
                selected: _selected == AccountType.single,
                onTap: () => setState(() => _selected = AccountType.single),
              ),
              const SizedBox(height: 12),
              OptionCard(
                icon: Icons.family_restroom_rounded,
                title: 'Bir yakınımın sürecini takip ediyorum',
                subtitle:
                    'Ben zaten evliyim; çocuğumun/yakınımın izin verdiği eşleşmeleri '
                    'görmek istiyorum. Kendim için kimseyle eşleşmiyorum.',
                selected: _selected == AccountType.guardian,
                onTap: () => setState(() => _selected = AccountType.guardian),
              ),
              const Spacer(),
              GradientButton(
                label: 'Devam et',
                onPressed: _selected == null
                    ? null
                    : () {
                        context.read<AuthCubit>().selectAccountType(_selected!);
                        context.push('/consent');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
