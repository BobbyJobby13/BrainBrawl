import 'package:brainbrawl/platform/display_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a plain launch is the host console', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[],
        environment: const <String, String>{},
      ),
      isFalse,
    );
  });

  test('the flag alone makes a display', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[DisplayMode.flag],
        environment: const <String, String>{},
      ),
      isTrue,
    );
  });

  test('the environment alone makes a display', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[],
        environment: const <String, String>{
          DisplayMode.roleKey: DisplayMode.displayRole,
        },
      ),
      isTrue,
    );
  });

  test('a fresh marker alone makes a display', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[],
        environment: const <String, String>{},
        markerAge: const Duration(seconds: 2),
      ),
      isTrue,
    );
  });

  test('a stale marker is ignored so a manual launch stays the console', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[],
        environment: const <String, String>{},
        markerAge: const Duration(minutes: 5),
      ),
      isFalse,
    );
  });

  test('another role in the environment is not a display', () {
    expect(
      DisplayMode.isDisplayRequest(
        args: const <String>[],
        environment: const <String, String>{
          DisplayMode.roleKey: 'console',
        },
      ),
      isFalse,
    );
  });
}
