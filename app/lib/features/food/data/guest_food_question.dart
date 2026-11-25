import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/presentation/auth_controller.dart';

/// Whether to add the food a guest added on this phone to the account signing
/// in, while that is asked: how many items. The sync controller asks,
/// `GuestFoodPrompt` shows the question and answers it.
class GuestFoodQuestionController extends Notifier<int?> {
  Completer<bool?>? _answer;

  @override
  int? build() {
    // Signed out, or in as someone else, before answering: no longer asked.
    ref.listen(authControllerProvider, (previous, next) {
      if (next.value?.id != previous?.value?.id) _finish(null);
    });
    return null;
  }

  /// Whether to add the [count] items; null if the question was dropped.
  Future<bool?> ask(int count) {
    _finish(null);
    final answer = _answer = Completer();
    state = count;
    return answer.future;
  }

  void answer({required bool add}) => _finish(add);

  void _finish(bool? add) {
    _answer?.complete(add);
    _answer = null;
    state = null;
  }
}

final guestFoodQuestionProvider =
    NotifierProvider<GuestFoodQuestionController, int?>(
      GuestFoodQuestionController.new,
    );
