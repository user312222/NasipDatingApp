import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/report_user.dart';

sealed class SafetyState extends Equatable {
  const SafetyState();

  @override
  List<Object?> get props => [];
}

final class SafetyIdle extends SafetyState {
  const SafetyIdle();
}

final class SafetyBusy extends SafetyState {
  const SafetyBusy();
}

final class SafetyReported extends SafetyState {
  const SafetyReported();
}

final class SafetyBlocked extends SafetyState {
  const SafetyBlocked(this.targetUserId);
  final String targetUserId;

  @override
  List<Object?> get props => [targetUserId];
}

final class SafetyFailed extends SafetyState {
  const SafetyFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit({required ReportUser reportUser, required BlockUser blockUser})
    : _reportUser = reportUser,
      _blockUser = blockUser,
      super(const SafetyIdle());

  final ReportUser _reportUser;
  final BlockUser _blockUser;

  Future<void> report({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  }) async {
    emit(const SafetyBusy());
    final result = await _reportUser(
      ReportUserParams(
        targetUserId: targetUserId,
        reason: reason,
        details: details,
      ),
    );
    switch (result) {
      case Ok<void>():
        emit(const SafetyReported());
      case Err<void>(:final failure):
        emit(SafetyFailed(failure.message));
    }
  }

  Future<void> block(String targetUserId) async {
    emit(const SafetyBusy());
    final result = await _blockUser(targetUserId);
    switch (result) {
      case Ok<void>():
        emit(SafetyBlocked(targetUserId));
      case Err<void>(:final failure):
        emit(SafetyFailed(failure.message));
    }
  }
}
