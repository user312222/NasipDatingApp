import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/restart/restart_app.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/domain/entities/account_type.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../profile/presentation/widgets/profile_summary_card.dart';
import '../bloc/account_cubit.dart';

/// FR-7: the "Hesap & Veri" screen. Reachable by both single and
/// guardian accounts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  Future<void> _confirmDelete(BuildContext context, String userId) async {
    final cubit = context.read<AccountCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabın silinsin mi?'),
        content: const Text(
          'Profilin, fotoğrafların, eşleşmelerin, mesajların ve doğrulama '
          'sonucun kalıcı olarak silinir. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hesabımı sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.deleteAccount(userId);
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final cubit = context.read<AccountCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text(
          'Profilin ve tüm verilerin olduğu gibi kalır; sadece bu cihazdaki '
          'oturumun kapanır. İstediğin zaman aynı numarayla tekrar giriş '
          'yapabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.logOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final user = context.read<AuthCubit>().currentUser;
    final userId = user?.id ?? 'unknown_user';
    return BlocConsumer<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state is AccountDeleted) RestartApp.restart(context);
        if (state is AccountDeleteFailed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AccountLoggedOut) RestartApp.restart(context);
        if (state is AccountLogOutFailed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final deleting = state is AccountDeleting || state is AccountDeleted;
        final loggingOut =
            state is AccountLoggingOut || state is AccountLoggedOut;
        return Scaffold(
          appBar: AppBar(title: const Text('Hesap & Veri')),
          body: WizardBackdrop(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.plumFill, colors.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.plumFill.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hesabın',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+90 ${user.phone}',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Guardian accounts have no profile (FR-8.2).
                if (user?.accountType == AccountType.single) ...[
                  ProfileSummaryCard(
                    userId: userId,
                    enabled: !deleting && !loggingOut,
                  ),
                  const SizedBox(height: 12),
                ],
                ValueListenableBuilder<bool>(
                  valueListenable:
                      sl<AppPreferences>().showMatchMessagePreviews,
                  builder: (context, showPreviews, _) => SectionCard(
                    icon: Icons.visibility_outlined,
                    title: 'Eşleşmeler listesinde mesaj önizlemesi',
                    body: showPreviews
                        ? 'Her eşleşme satırında son mesajın bir kısmı görünür. '
                              'Kapatırsan yalnızca şehir gibi profil bilgisi görünür.'
                        : 'Eşleşme satırlarında yalnızca profil bilgisi görünüyor; '
                              'mesaj metni gösterilmiyor.',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: showPreviews,
                        onChanged: (v) =>
                            sl<AppPreferences>().setShowMatchMessagePreviews(v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: colors.plumFill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SectionCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Doğrulama verin',
                  body:
                      'Selfie ve biyometrik verin Bi Nasip’te hiç saklanmaz; '
                      'işlem bağımsız bir doğrulama sağlayıcısında yapılır. Bizde '
                      'yalnızca "doğrulandı" bilgisi ve zamanı tutulur.',
                ),
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.logout_rounded,
                  title: 'Oturum',
                  body: 'Bu cihazdaki oturumunu kapatır; verilerin olduğu gibi kalır.',
                  child: OutlinedButton.icon(
                    onPressed: (loggingOut || deleting)
                        ? null
                        : () => _confirmLogOut(context),
                    icon: loggingOut
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Çıkış yap'),
                    style: sectionActionStyle(context),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.delete_outline_rounded,
                  title: 'Verilerin',
                  danger: true,
                  body:
                      'KVKK kapsamında hesabını ve tüm verini istediğin zaman '
                      'silebilirsin.',
                  child: OutlinedButton.icon(
                    onPressed: (deleting || loggingOut)
                        ? null
                        : () => _confirmDelete(context, userId),
                    icon: deleting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Hesabımı ve verilerimi sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
