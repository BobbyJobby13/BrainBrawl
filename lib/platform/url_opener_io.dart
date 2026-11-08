import 'dart:io';

/// Hands a URL to the operating system's default browser.
///
/// A plugin would be the usual route, but this app ships no plugin plumbing and
/// `open` / `start` / `xdg-open` cover every desktop target it builds for
/// without touching pubspec, the lockfile or the macOS Podfile.
Future<void> openExternalUrl(String url) async {
  final String target = url.trim();
  if (target.isEmpty) return;

  try {
    if (Platform.isMacOS) {
      await Process.run('open', <String>[target]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', <String>['/c', 'start', '', target]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[target]);
    }
  } catch (_) {
    // A missing browser or handler must never take the console down mid-game.
  }
}
