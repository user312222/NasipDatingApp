part of 'family_visibility_cubit.dart';

sealed class FamilyVisibilityState extends Equatable {
  const FamilyVisibilityState();

  @override
  List<Object?> get props => [];
}

final class FamilyVisibilityLoading extends FamilyVisibilityState {
  const FamilyVisibilityLoading();
}

/// The current choice could not be read. The chat hides the control
/// instead of showing a switch that might be wrong about what the family
/// can see.
final class FamilyVisibilityUnavailable extends FamilyVisibilityState {
  const FamilyVisibilityUnavailable();
}

final class FamilyVisibilityReady extends FamilyVisibilityState {
  const FamilyVisibilityReady({
    required this.visible,
    this.isSaving = false,
    this.saveFailed = false,
  });

  final bool visible;
  final bool isSaving;

  /// The last change was not saved; [visible] is back to the stored value.
  final bool saveFailed;

  @override
  List<Object?> get props => [visible, isSaving, saveFailed];
}
