/// Non-web stand-in for [BuzzerSocket].
///
/// Buzzers over WebSocket only make sense on Flutter web (the app's target).
/// On every other platform this throws so the console can show a clear message
/// instead of failing to compile.
class BuzzerSocket {
  BuzzerSocket({
    required String url,
    required void Function(Object? message) onMessage,
    required void Function(String? error) onError,
    void Function()? onConnected,
  }) {
    onError('Hardware buzzers are only supported in the web build.');
    throw UnsupportedError(
      'Hardware buzzers are only supported in the web build.',
    );
  }

  void close() {}
}
