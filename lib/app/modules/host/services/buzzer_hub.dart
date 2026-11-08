import 'dart:convert';

import 'package:get/get.dart';

import 'buzzer_socket.dart';

/// One press of a buzzer button.
class BuzzerHit {
  BuzzerHit({required this.deviceId, required this.source, required this.at});

  final String deviceId;

  /// `keyboard`, `hardware`, or `manual` (host tapped the player card).
  final String source;
  final DateTime at;
}

/// Central landing point for every way a player can buzz.
///
/// Nothing here knows what a "team" is: it collects ordered presses and lets
/// the game controller decide who is allowed to score. That split is what makes
/// new buzzer hardware a drop-in later — a box only has to produce a device id.
class BuzzerHub {
  BuzzerHub();

  final RxBool armed = false.obs;
  final RxList<BuzzerHit> hits = <BuzzerHit>[].obs;
  final RxBool connected = false.obs;
  final RxString connectionStatus = 'No receiver connected'.obs;
  final RxSet<String> seenDevices = <String>{}.obs;

  /// Called for every accepted press, in arrival order.
  void Function(BuzzerHit hit)? onBuzz;

  BuzzerSocket? _socket;

  void arm() => armed.value = true;

  void disarm() => armed.value = false;

  /// Clears the press queue but keeps the assignment map, so the next player
  /// can buzz on the same device.
  void reset() => hits.clear();

  /// Registers a press. Duplicate presses from the same device and presses from
  /// a disarmed hub are ignored, which is what stops a held button from
  /// flooding the queue.
  void press(String deviceId, {String source = 'manual'}) {
    final String id = deviceId.trim();
    if (id.isEmpty || !armed.value) return;
    if (hits.any((BuzzerHit hit) => hit.deviceId == id)) return;

    seenDevices.add(id);
    final BuzzerHit hit = BuzzerHit(deviceId: id, source: source, at: DateTime.now());
    hits.add(hit);
    onBuzz?.call(hit);
  }

  Future<void> connect(String url) async {
    disconnect();
    final String trimmed = url.trim();
    if (trimmed.isEmpty) {
      connectionStatus.value = 'Enter the receiver URL first.';
      return;
    }

    connectionStatus.value = 'Connecting…';
    try {
      _socket = BuzzerSocket(
        url: trimmed,
        onConnected: () {
          connected.value = true;
          connectionStatus.value = 'Receiver connected';
        },
        onMessage: (Object? message) {
          final String? device = _deviceFrom(message);
          if (device != null) press(device, source: 'hardware');
        },
        onError: (String? error) {
          connected.value = false;
          connectionStatus.value = error ?? 'Buzzer receiver unavailable.';
        },
      );
    } catch (error) {
      connected.value = false;
      connectionStatus.value = error.toString();
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    connected.value = false;
    if (!connectionStatus.value.startsWith('No receiver')) {
      connectionStatus.value = 'No receiver connected';
    }
  }

  /// Accepts `{"device":"A1"}`, `{"buzzer":"A1"}`, `{"id":"A1"}` or bare `A1`.
  String? _deviceFrom(Object? message) {
    if (message == null) return null;
    final String raw = message.toString().trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('{')) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map) {
          final dynamic value =
              decoded['device'] ?? decoded['buzzer'] ?? decoded['id'] ?? decoded['player'];
          return value?.toString().trim();
        }
      } catch (_) {
        return null;
      }
    }
    return raw;
  }

  void dispose() => disconnect();
}
