import 'package:equatable/equatable.dart';

import '../result/result.dart';

/// A single unit of business logic. Each use case does one thing
/// (`SubmitWaitlistEntry`, `SendMessage`, `LikeProfile`, ...) and depends
/// only on domain-layer repository interfaces — never on a concrete data
/// source, so it can be unit-tested with a fake repository and no Firebase.
abstract class UseCase<R, Params> {
  Future<Result<R>> call(Params params);
}

/// Use for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
