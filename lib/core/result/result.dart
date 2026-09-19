import '../error/failures.dart';

/// The outcome of any repository/use-case call: either a value of type
/// [T] ([Ok]) or a [Failure] ([Err]). Replaces the exceptions-as-control-flow
/// pattern at architecture boundaries — a `Future<Result<T>>` return type
/// means "this can fail, and the caller must say what happens when it does"
/// is visible in the signature, and Dart 3 pattern matching makes handling
/// both branches exhaustive and compiler-checked:
///
/// ```dart
/// final result = await submitWaitlistEntry(entry);
/// switch (result) {
///   Ok(:final value) => emit(WaitlistSuccess(value)),
///   Err(:final failure) => emit(WaitlistError(failure.message)),
/// }
/// ```
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
