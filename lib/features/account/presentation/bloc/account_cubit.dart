import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/log_out.dart';
import '../../domain/usecases/delete_account.dart';

sealed class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

final class AccountIdle extends AccountState {
  const AccountIdle();
}

final class AccountDeleting extends AccountState {
  const AccountDeleting();
}

final class AccountDeleted extends AccountState {
  const AccountDeleted();
}

final class AccountDeleteFailed extends AccountState {
  const AccountDeleteFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class AccountLoggingOut extends AccountState {
  const AccountLoggingOut();
}

final class AccountLoggedOut extends AccountState {
  const AccountLoggedOut();
}

final class AccountLogOutFailed extends AccountState {
  const AccountLogOutFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({required DeleteAccount deleteAccount, required LogOut logOut})
    : _deleteAccount = deleteAccount,
      _logOut = logOut,
      super(const AccountIdle());

  final DeleteAccount _deleteAccount;
  final LogOut _logOut;

  Future<void> deleteAccount(String userId) async {
    emit(const AccountDeleting());
    final result = await _deleteAccount(userId);
    switch (result) {
      case Ok<void>():
        emit(const AccountDeleted());
      case Err<void>(:final failure):
        emit(AccountDeleteFailed(failure.message));
    }
  }

  /// Unlike [deleteAccount], nothing here is destructive — the account and
  /// all its data stay exactly as they are; only this device's session
  /// ends. `SettingsScreen` follows `AccountLoggedOut` up with
  /// `RestartApp.restart`, same as it does for `AccountDeleted`, so no
  /// in-memory mock state (matching, messaging, …) survives into whoever
  /// signs in next.
  Future<void> logOut() async {
    emit(const AccountLoggingOut());
    final result = await _logOut(const NoParams());
    switch (result) {
      case Ok<void>():
        emit(const AccountLoggedOut());
      case Err<void>(:final failure):
        emit(AccountLogOutFailed(failure.message));
    }
  }
}
