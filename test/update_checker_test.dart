import 'dart:convert';
import 'dart:io';

import 'package:brainbrawl/app/app_version.dart';
import 'package:brainbrawl/platform/app_update.dart';
import 'package:brainbrawl/platform/update_checker_io.dart';
import 'package:flutter_test/flutter_test.dart';

String _releaseJson({required String tag, String? name}) => jsonEncode(
      <String, Object?>{
        'tag_name': tag,
        'html_url':
            'https://github.com/BobbyJobby13/BrainBrawl/releases/tag/$tag',
        'name': name ?? 'Brain Brawl ${tag.replaceFirst('v', '')}',
      },
    );

Future<HttpServer> _serve(int statusCode, String body,
    {void Function(HttpRequest request)? onRequest}) async {
  final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((HttpRequest request) async {
    onRequest?.call(request);
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(body);
    await request.response.close();
  });
  return server;
}

Uri _endpointFor(HttpServer server) =>
    Uri.parse('http://${server.address.host}:${server.port}/releases/latest');

void main() {
  group('version comparison', () {
    test('orders releases numerically, not alphabetically', () {
      expect(compareVersions('1.9.9', '1.10.0'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('normalises tags, build numbers and pre-releases', () {
      expect(normaliseVersion('v1.2.3'), '1.2.3');
      expect(normaliseVersion('V1.2.3'), '1.2.3');
      expect(normaliseVersion('1.2.3+7'), '1.2.3');
      expect(normaliseVersion('1.2.3-beta.1'), '1.2.3');
      expect(normaliseVersion('1.2'), '1.2.0');
      expect(normaliseVersion(''), isNull);
      expect(normaliseVersion('latest'), isNull);
    });
  });

  group('release payload', () {
    test('a newer release becomes an update with its download page', () {
      final AppUpdate? update =
          parseLatestRelease(_releaseJson(tag: 'v1.1.0'), '1.0.0');
      expect(update, isNotNull);
      expect(update!.version, '1.1.0');
      expect(update.downloadUrl,
          'https://github.com/BobbyJobby13/BrainBrawl/releases/tag/v1.1.0');
      expect(update.releaseName, 'Brain Brawl 1.1.0');
    });

    test('the same or an older release is not an update', () {
      expect(parseLatestRelease(_releaseJson(tag: 'v1.0.0'), '1.0.0'), isNull);
      expect(parseLatestRelease(_releaseJson(tag: 'v0.9.0'), '1.0.0'), isNull);
    });

    test('a repository with no releases yet is not an update', () {
      expect(parseLatestRelease('{"message":"Not Found"}', '1.0.0'), isNull);
    });

    test('garbage from a proxy or captive portal is ignored', () {
      expect(parseLatestRelease('<html>502 Bad Gateway</html>', '1.0.0'), isNull);
      expect(parseLatestRelease('', '1.0.0'), isNull);
      expect(parseLatestRelease('[1,2,3]', '1.0.0'), isNull);
    });
  });

  group('over the wire', () {
    test('the desktop checker parses a release served over HTTP', () async {
      final List<String> paths = <String>[];
      final HttpServer server = await _serve(
        HttpStatus.ok,
        _releaseJson(tag: 'v1.2.0'),
        onRequest: (HttpRequest request) => paths.add(request.uri.path),
      );
      addTearDown(() => server.close(force: true));

      final AppUpdate? update = await queryLatestRelease(
        _endpointFor(server),
        '1.0.0',
      );

      expect(update?.version, '1.2.0');
      expect(update?.downloadUrl, contains('/releases/tag/v1.2.0'));
      expect(paths, <String>['/releases/latest']);
    });

    test('sends a User-Agent, because GitHub rejects requests without one',
        () async {
      String? userAgent;
      final HttpServer server = await _serve(
        HttpStatus.ok,
        _releaseJson(tag: 'v1.2.0'),
        onRequest: (HttpRequest request) =>
            userAgent = request.headers.value(HttpHeaders.userAgentHeader),
      );
      addTearDown(() => server.close(force: true));

      await queryLatestRelease(_endpointFor(server), '1.0.0');
      expect(userAgent, contains('BrainBrawl'));
      expect(userAgent, contains('1.0.0'));
    });

    test('an error response is ignored instead of thrown', () async {
      final HttpServer server =
          await _serve(HttpStatus.forbidden, '{"message":"rate limited"}');
      addTearDown(() => server.close(force: true));

      expect(await queryLatestRelease(_endpointFor(server), '1.0.0'), isNull);
    });

    test('an unreachable host resolves to null, not an exception', () async {
      // Port 1 on loopback refuses connections; a venue with no wifi or a
      // blocked endpoint must behave the same way.
      final AppUpdate? update = await queryLatestRelease(
        Uri.parse('http://127.0.0.1:1/releases/latest'),
        '1.0.0',
        timeout: const Duration(seconds: 2),
      );
      expect(update, isNull);
    });
  });

  test('a bad download URL is refused before launching anything', () async {
    expect(await openDownloadPage('javascript:alert(1)'), isFalse);
    expect(await openDownloadPage(''), isFalse);
  });

  test('the check is a no-op away from the desktop builds', () async {
    // Tests run on Linux, where the packaged-app check deliberately stays quiet.
    expect(await checkForAppUpdate('1.0.0'), isNull);
  });

  test('the running version matches pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no x.y.z version');
    expect(
      match!.group(1),
      appVersion,
      reason: 'keep lib/app/app_version.dart in sync with pubspec.yaml',
    );
  });
}
