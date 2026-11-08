import 'package:flutterwebapp_reload_detector/flutterwebapp_reload_detector.dart';

/// Web implementation, forwarding to the browser-only package.
class AppReloadDetector {
  static void onReload(void Function() callback) =>
      WebAppReloadDetector.onReload(callback);
}
