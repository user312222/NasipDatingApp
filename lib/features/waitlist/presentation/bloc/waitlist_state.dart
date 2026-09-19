part of 'waitlist_cubit.dart';

sealed class WaitlistState extends Equatable {
  const WaitlistState();

  @override
  List<Object?> get props => [];
}

final class WaitlistIdle extends WaitlistState {
  const WaitlistIdle();
}

final class WaitlistSubmitting extends WaitlistState {
  const WaitlistSubmitting();
}

final class WaitlistSuccess extends WaitlistState {
  const WaitlistSuccess(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class WaitlistFailure extends WaitlistState {
  const WaitlistFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
