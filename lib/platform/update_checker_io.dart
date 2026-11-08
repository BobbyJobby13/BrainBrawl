import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_update.dart';

/// GitHub's "latest release" endpoint for this repository.
///
/// The `v*` tag build in `.github/workflows/desktop-builds.yml` attaches the DMG
/// and MSI to a GitHub Release, so this always points at real installers.
const String latestReleaseEndpoint =
    'https://api.github.com/repos/BobbyJobby13/BrainBrawl/releases/latest';

/// Asks GitHub for the newest release and returns it only if it beats
/// [currentVersion].
///
/// Desktop builds only: the packaged macOS and Windows apps can be out of date,
/// whereas the browser build always loads whatever the server has.
Future<AppUpdate?> checkForAppUpdate(String currentVersion) async {
  if (!Platform.isMacOS && !Platform.isWindows) return null;
  return queryLatestRelease(Uri.parse(latestReleaseEndpoint), currentVersion);
}

/// The network half of [checkForAppUpdate], with the endpoint injected so tests
/// can serve their own responses.
///
/// Every failure — offline, a blocked school network, a rate limit, a proxy
/// returning HTML — resolves to null. A launch check must never block, warn or
/// crash the app.
Future<AppUpdate?> queryLatestRelease(
  Uri endpoint,
  String currentVersion, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final HttpClient client = HttpClient()..connectionTimeout = timeout;
  try {
    final HttpClientRequest request =
        await client.getUrl(endpoint).timeout(timeout);
    // GitHub rejects requests without a User-Agent, and the version label makes
    // the traffic identifiable in case it ever needs diagnosing.
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'BrainBrawl/$currentVersion (desktop)',
    );
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );

    final HttpClientResponse response =
        await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final String body =
        await response.transform(utf8.decoder).join().timeout(timeout);
    return parseLatestRelease(body, currentVersion);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Opens the release page in the user's default browser.
///
/// The app has no `url_launcher` dependency, so this hands the URL to the
/// platform's own opener. Returns false when that fails; the caller then shows
/// the URL so it can be opened by hand.
Future<bool> openDownloadPage(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return false;
  }
  try {
    if (Platform.isMacOS) {
      final ProcessResult result = await Process.run('open', <String>[url]);
      return result.exitCode == 0;
    }
    if (Platform.isWindows) {
      // rundll32 raises no console window; `cmd /c start` flashes one.
      final ProcessResult result = await Process.run(
        'rundll32',
        <String>['url.dll,FileProtocolHandler', url],
      );
      return result.exitCode == 0;
    }
    if (Platform.isLinux) {
      final ProcessResult result = await Process.run('xdg-open', <String>[url]);
      return result.exitCode == 0;
    }
  } catch (_) {
    // The dialog also prints the URL, so this is recoverable.
  }
  return false;
}
