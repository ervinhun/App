import 'package:app/core/storage/hint_storage.dart';

class FakeHintStorage extends HintStorage {
  FakeHintStorage({this.swipeDone = false});

  bool swipeDone;

  @override
  Future<bool> swipeHintDone() async => swipeDone;

  @override
  Future<void> markSwipeHintDone() async => swipeDone = true;
}
