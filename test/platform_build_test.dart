// Compile smoke test for the desktop builds.
//
// `flutter test` compiles this for the Dart VM, i.e. with every conditional
// import resolved to its non-web branch — the same code the macOS and Windows
// builds use. Importing main.dart therefore pulls in every route, view and
// controller and fails here if any of them still depends on a browser-only
// library (dart:html, dart:js, package:web).
import 'package:brainbrawl/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the whole app tree compiles off the web', () {
    expect(app.main, isNotNull);
  });
}
