import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Shares the live game state with the player display window.
///
/// The console and the display are separate processes — Flutter runs one window
/// per process — so they meet at a small JSON file in the user's temp
/// directory: the console rewrites it whenever something changes, the display
/// polls it four times a second. A file keeps this free of sockets, ports and
/// the "accept incoming connections" prompt that a listening socket would raise
/// for an unsigned app.
class LiveLink {
  static final File _file =
      File('${Directory.systemTemp.path}/brainbrawl_live_state.json');

  String? _lastPublished;
  Timer? _pollTimer;

  bool get canOpenDisplay => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

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

  /// Starts a second copy of the app with `--display`, for the projector.
  /// Returns an error message, or null when it launched.
  Future<String?> openDisplay() async {
    final String executable = Platform.resolvedExecutable;
    try {
      if (Platform.isMacOS) {
        // `open -n` launches a second instance the way Finder would, which is
        // the only way macOS gives the copy its own dock tile and window.
        final int marker = executable.indexOf('.app/Contents/MacOS/');
        final String bundle =
            marker > 0 ? executable.substring(0, marker + 4) : executable;
        final ProcessResult result = await Process.run(
          'open',
          <String>['-n', bundle, '--args', '--display'],
        );
        if (result.exitCode != 0) {
          final String detail = result.stderr.toString().trim();
          return detail.isEmpty
              ? 'macOS refused to open the display window.'
              : detail;
        }
        return null;
      }
      await Process.start(
        executable,
        <String>['--display'],
        mode: ProcessStartMode.detached,
      );
      return null;
    } catch (error) {
      return 'Could not open the display window: $error';
    }
  }
}
