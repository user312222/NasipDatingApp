import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/restart/restart_app.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AccountLoggedOut) RestartApp.restart(context);
        if (state is AccountLogOutFailed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final deleting = state is AccountDeleting || state is AccountDeleted;
        final loggingOut =
            state is AccountLoggingOut || state is AccountLoggedOut;
        return Scaffold(
          appBar: AppBar(title: const Text('Hesap & Veri')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (user != null) ...[
                Text('Hesabın', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '+90 ${user.phone}',
                  style: textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
                ),
                const SizedBox(height: 24),
              ],
              Text('Doğrulama verin', style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Selfie ve biyometrik verin Bi Nasip’te hiç saklanmaz; '
                'işlem bağımsız bir doğrulama sağlayıcısında yapılır. Bizde '
                'yalnızca "doğrulandı" bilgisi ve zamanı tutulur.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
              Text('Verilerin', style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'KVKK kapsamında hesabını ve tüm verini istediğin zaman '
                'silebilirsin.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
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
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
