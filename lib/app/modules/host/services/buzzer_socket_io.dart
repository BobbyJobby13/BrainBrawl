import 'dart:async';
import 'dart:io';

/// WebSocket client for hardware buzzer boxes on desktop and mobile builds.
///
/// Keeps the exact same wire format as the browser version: a buzzer system only
/// has to send a short identifier when a button is pressed, either as plain text
/// (`A1`) or as JSON (`{"device":"A1"}`).
class BuzzerSocket {
  BuzzerSocket({
    required String url,
    required void Function(Object? message) onMessage,
    required void Function(String? error) onError,
    void Function()? onConnected,
  }) {
    _connect(url, onMessage, onError, onConnected);
  }

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  Future<void> _connect(
    String url,
    void Function(Object? message) onMessage,
    void Function(String? error) onError,
    void Function()? onConnected,
  ) async {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      onError('Use a ws:// or wss:// address, like ws://192.168.1.50:8080/buzzers');
      return;
    }

    try {
      final WebSocket socket = await WebSocket.connect(uri.toString());
      if (_closed) {
        await socket.close();
        return;
      }
      _socket = socket;
      // Keeps the link alive on flaky venue wifi without extra work in the UI.
      socket.pingInterval = const Duration(seconds: 20);
      onConnected?.call();
      _subscription = socket.listen(
        (dynamic data) {
          if (data is String) {
            onMessage(data);
          } else if (data is List<int>) {
            onMessage(String.fromCharCodes(data));
          }
        },
        onError: (Object _) =>
            onError('The buzzer receiver reported an error.'),
        onDone: () {
          if (!_closed) {
            onError('Buzzer receiver disconnected.');
          }
        },
        cancelOnError: false,
      );
    } on SocketException {
      onError(
        'Could not reach $url — check the receiver is running and on this network.',
      );
    } on WebSocketException {
      onError('$url refused the connection. Is it a WebSocket address?');
    } on HandshakeException {
      onError('$url did not accept the connection handshake.');
    } catch (error) {
      onError(error.toString());
    }
  }

  void close() {
    _closed = true;
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
  }
}
