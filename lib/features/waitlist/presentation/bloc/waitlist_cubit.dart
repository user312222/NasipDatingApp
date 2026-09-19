import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/waitlist_entry.dart';
import '../../domain/usecases/submit_waitlist_entry.dart';
import '../../../../core/result/result.dart';

part 'waitlist_state.dart';

class WaitlistCubit extends Cubit<WaitlistState> {
  WaitlistCubit({required SubmitWaitlistEntry submitWaitlistEntry})
    : _submitWaitlistEntry = submitWaitlistEntry,
      super(const WaitlistIdle());

  final SubmitWaitlistEntry _submitWaitlistEntry;

  Future<void> submit({required String name, required String contact, String? city}) async {
    emit(const WaitlistSubmitting());
    final result = await _submitWaitlistEntry(
      WaitlistEntry(name: name, contact: contact, city: city),
    );
    switch (result) {
      case Ok<void>():
        emit(WaitlistSuccess(name));
      case Err<void>(:final failure):
        emit(WaitlistFailure(failure.message));
    }
  }
}
