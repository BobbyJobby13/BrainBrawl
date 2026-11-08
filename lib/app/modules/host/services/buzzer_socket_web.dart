import 'dart:html' as html;

/// Minimal WebSocket client for hardware buzzer boxes.
///
/// The wire format is intentionally dumb: a buzzer system only has to send a
/// short identifier when a button is pressed, either as plain text (`A1`) or as
/// JSON (`{"device":"A1"}`). Anything that can open a WebSocket and emit one of
/// those can drive the console.
class BuzzerSocket {
  BuzzerSocket({
    required String url,
    required void Function(Object? message) onMessage,
    required void Function(String? error) onError,
    void Function()? onConnected,
  }) {
    try {
      final html.WebSocket socket = html.WebSocket(url);
      _socket = socket;
      socket.onOpen.listen((_) => onConnected?.call());
      socket.onMessage.listen((html.MessageEvent event) {
        onMessage(event.data);
      });
      socket.onError.listen((_) => onError('The buzzer receiver reported an error.'));
      socket.onClose.listen((_) => onError('Buzzer receiver disconnected.'));
    } catch (error) {
      onError(error.toString());
    }
  }

  html.WebSocket? _socket;

  void close() {
    try {
      _socket?.close();
    } catch (_) {
      // Closing a half-open socket is not worth surfacing.
    }
    _socket = null;
  }
}
