part of 'guardian_cubit.dart';

sealed class GuardianState extends Equatable {
  const GuardianState();

  @override
  List<Object?> get props => [];
}

final class GuardianIdle extends GuardianState {
  const GuardianIdle();
}

final class GuardianLinking extends GuardianState {
  const GuardianLinking();
}

final class GuardianLinked extends GuardianState {
  const GuardianLinked();
}

final class GuardianLinkFailed extends GuardianState {
  const GuardianLinkFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class GuardianMatchesLoading extends GuardianState {
  const GuardianMatchesLoading();
}

final class GuardianMatchesLoaded extends GuardianState {
  const GuardianMatchesLoaded(this.matches, {this.singleName});
  final List<FamilyVisibleMatch> matches;

  /// Whose matches these are. Null when it could not be read - the list is
  /// still shown, just without a name.
  final String? singleName;

  @override
  List<Object?> get props => [matches, singleName];
}

final class GuardianMatchesFailed extends GuardianState {
  const GuardianMatchesFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
