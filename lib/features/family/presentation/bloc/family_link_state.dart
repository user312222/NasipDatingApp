part of 'family_link_cubit.dart';

sealed class FamilyLinkState extends Equatable {
  const FamilyLinkState();

  @override
  List<Object?> get props => [];
}

final class FamilyLinkLoading extends FamilyLinkState {
  const FamilyLinkLoading();
}

final class FamilyLinkError extends FamilyLinkState {
  const FamilyLinkError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class FamilyLinkLoaded extends FamilyLinkState {
  const FamilyLinkLoaded({required this.inviteCode, required this.matches});
  final String inviteCode;
  final List<Match> matches;

  @override
  List<Object?> get props => [inviteCode, matches];
}
