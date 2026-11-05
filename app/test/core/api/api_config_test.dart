import 'package:app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the app refuses to start without GOOGLE_SERVER_CLIENT_ID',
    () => expect(app.main, throwsStateError),
    skip: const bool.hasEnvironment('GOOGLE_SERVER_CLIENT_ID'),
  );
}
