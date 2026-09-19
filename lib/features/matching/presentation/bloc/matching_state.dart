part of 'matching_cubit.dart';

sealed class MatchingState extends Equatable {
  const MatchingState();

  @override
  List<Object?> get props => [];
}

final class MatchingLoading extends MatchingState {
  const MatchingLoading();
}

final class MatchingError extends MatchingState {
  const MatchingError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class MatchingLoaded extends MatchingState {
  const MatchingLoaded({
    required this.candidates,
    this.currentIndex = 0,
    required this.filter,
    this.isSwiping = false,
    this.justMatched,
    this.swipeError,
  });

  final List<Candidate> candidates;
  final int currentIndex;
  final CandidateFilter filter;
  final bool isSwiping;

  /// FR-4.2: set for exactly one emission right after a mutual like —
  /// the screen shows the celebration on a `BlocListener` and never
  /// needs to clear it back out itself.
  final Match? justMatched;

  /// FR-4.3 (or any other swipe failure) — same one-shot-emission idea.
  final String? swipeError;

  Candidate? get current => currentIndex < candidates.length ? candidates[currentIndex] : null;

  bool get exhausted => currentIndex >= candidates.length;

  MatchingLoaded copyWith({
    List<Candidate>? candidates,
    int? currentIndex,
    CandidateFilter? filter,
    bool? isSwiping,
    Match? justMatched,
    String? swipeError,
  }) {
    return MatchingLoaded(
      candidates: candidates ?? this.candidates,
      currentIndex: currentIndex ?? this.currentIndex,
      filter: filter ?? this.filter,
      isSwiping: isSwiping ?? false,
      justMatched: justMatched,
      swipeError: swipeError,
    );
  }

  @override
  List<Object?> get props => [
    candidates,
    currentIndex,
    filter,
    isSwiping,
    justMatched,
    swipeError,
  ];
}
