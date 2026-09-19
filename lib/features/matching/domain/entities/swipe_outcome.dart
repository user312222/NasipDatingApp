import 'package:equatable/equatable.dart';

import 'match.dart';

enum SwipeAction { like, pass }

/// What happens right after a swipe: a plain acknowledgement, or — for a
/// `like` that turns out to be mutual — a freshly created [match].
class SwipeOutcome extends Equatable {
  const SwipeOutcome({required this.matched, this.match});

  final bool matched;
  final Match? match;

  @override
  List<Object?> get props => [matched, match];
}
