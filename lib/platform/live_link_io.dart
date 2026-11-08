import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'display_mode.dart';

/// Shares the live game state with the player display window.
///
/// The console and the display are separate processes — Flutter runs one window
/// per process — so they meet at a small JSON file in the user's temp
/// directory: the console rewrites it whenever something changes, the display
/// polls it four times a second. A file keeps this free of sockets, ports and
/// the "accept incoming connections" prompt that a listening socket would raise
/// for an unsigned app.
class LiveLink {
  static final String _dir = Directory.systemTemp.path;

  static final File _file = File('$_dir/brainbrawl_live_state.json');

  /// Written by the console just before it starts the display copy, so the copy
  /// knows it is a display even when macOS drops the command-line arguments.
  static final File _request = File('$_dir/brainbrawl_display_request');

  /// The display writes this once a second. Its appearance is how the console
  /// knows the second window really came up instead of guessing.
  static final File _beat = File('$_dir/brainbrawl_display_beat');

  static Timer? _beatTimer;
  String? _lastPublished;
  Timer? _pollTimer;

  bool get canOpenDisplay =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// True when this process is the projector board rather than the console.
  static bool isDisplayInstance(List<String> args) {
    Duration? markerAge;
    try {
      if (_request.existsSync()) {
        markerAge = DateTime.now().difference(_request.lastModifiedSync());
      }
    } catch (_) {
      markerAge = null;
    }
    final bool display = DisplayMode.isDisplayRequest(
      args: args,
      environment: Platform.environment,
      markerAge: markerAge,
    );
    if (display) {
      // Consume the marker so a window the host opens later is a console again.
      try {
        if (_request.existsSync()) _request.deleteSync();
      } catch (_) {}
    }
    return display;
  }

  /// Advertises the display to the console. Cheap enough to run every second and
  /// it stops by itself when the window closes.
  static void startDisplayHeartbeat() {
    _beatTimer ??= Timer.periodic(const Duration(seconds: 1), (Timer _) {
      try {
        _beat.writeAsStringSync(
          '${DateTime.now().millisecondsSinceEpoch}',
          flush: true,
        );
      } catch (_) {
        // Losing the heartbeat must never interrupt the board on screen.
      }
    });
  }

  /// Called by the console a few times a second; writes only when the board
  /// actually changed, so an idle game costs nothing.
  void publish(Map<String, dynamic> snapshot) {
    try {
      final String encoded = jsonEncode(snapshot);
      if (encoded == _lastPublished) return;
      _lastPublished = encoded;
      final File staged = File('${_file.path}.tmp');
      staged.writeAsStringSync(encoded, flush: true);
      // Rename so the display can never read a half-written snapshot.
      staged.renameSync(_file.path);
    } catch (_) {
      // A failed snapshot must never interrupt a live game.
    }
  }

  /// Called by the display: emits the board each time the console changes it.
  Stream<Map<String, dynamic>> watch() {
    final StreamController<Map<String, dynamic>> controller =
        StreamController<Map<String, dynamic>>.broadcast();
    String? lastSeen;

    controller.onListen = () {
      _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (Timer _) {
        try {
          if (!_file.existsSync()) return;
          final String raw = _file.readAsStringSync();
          if (raw == lastSeen) return;
          lastSeen = raw;
          final dynamic decoded = jsonDecode(raw);
          if (decoded is Map) {
            controller.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // A truncated read simply waits for the next tick.
        }
      });
    };

    controller.onCancel = () {
      _pollTimer?.cancel();
      _pollTimer = null;
    };

    return controller.stream;
  }

  static Future<bool> _awaitHeartbeat() async {
    final DateTime deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (_beat.existsSync()) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
  }

  /// Starts a second copy of the app as the projector board. Returns an error
  /// message, or null once that copy reports for duty.
  Future<String?> openDisplay() async {
    final String executable = Platform.resolvedExecutable;
    final List<String> failures = <String>[];

    try {
      if (_beat.existsSync()) _beat.deleteSync();
    } catch (_) {}
    try {
      _request.writeAsStringSync(
        '${DateTime.now().millisecondsSinceEpoch}',
        flush: true,
      );
    } catch (error) {
      failures.add('could not prepare the display: $error');
    }

    // `open -n` is the launch that behaves like Finder's: its own dock tile, and
    // it comes to the front. It cannot carry the environment, which is why the
    // marker file above goes with it.
    if (Platform.isMacOS) {
      try {
        final int marker = executable.indexOf('.app/Contents/MacOS/');
        final String bundle =
            marker > 0 ? executable.substring(0, marker + 4) : executable;
        final ProcessResult opened = await Process.run(
          'open',
          <String>['-n', bundle, '--args', DisplayMode.flag],
        );
        if (opened.exitCode == 0) {
          if (await _awaitHeartbeat()) return null;
          failures.add('the second window opened but never reported');
        } else {
          final String detail = opened.stderr.toString().trim();
          failures.add(
            'macOS refused the launch'
            '${detail.isEmpty ? '' : ': $detail'}',
          );
        }
      } catch (error) {
        failures.add('$error');
      }
    }

    // Fallback: run the bundle's own binary, the way `flutter run` does. This
    // one inherits the environment, so the role variable arrives for certain.
    if (!Platform.isMacOS || failures.isNotEmpty) {
      try {
        final Process child = await Process.start(
          executable,
          <String>[DisplayMode.flag],
          environment: <String, String>{
            ...Platform.environment,
            DisplayMode.roleKey: DisplayMode.displayRole,
          },
        );
        final StringBuffer errors = StringBuffer();
        child.stdout.listen((List<int> _) {});
        child.stderr.transform(utf8.decoder).listen(errors.write);
        if (await _awaitHeartbeat()) return null;
        final String detail = errors.toString().trim();
        failures.add(
          'the display copy started but stayed silent'
          '${detail.isEmpty ? '' : ': $detail'}',
        );
      } catch (error) {
        failures.add('$error');
      }
    }

    return 'The player display did not open. ${failures.join(' / ')}';
  }
}
