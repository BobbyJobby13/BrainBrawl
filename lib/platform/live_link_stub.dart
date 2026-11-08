import 'dart:async';

/// Web builds run in a browser tab, where the standalone HUD already owns the
/// projector window, so there is nothing to publish to and no second process.
class LiveLink {
  static bool isDisplayInstance(List<String> args) => false;

  static void startDisplayHeartbeat() {}

  void publish(Map<String, dynamic> snapshot) {}

  Stream<Map<String, dynamic>> watch() =>
      const Stream<Map<String, dynamic>>.empty();

  bool get canOpenDisplay => false;

  Future<String?> openDisplay() async =>
      'The player display opens as a second window in the desktop app.';
}
