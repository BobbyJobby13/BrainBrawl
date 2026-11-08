import 'dart:convert';

/// Update metadata and version arithmetic for the desktop update check.
///
/// Deliberately free of `dart:io` so the rules can be unit tested anywhere and
/// the web build can share them unchanged.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.downloadUrl,
    this.releaseName,
  });

  /// Normalised release version, e.g. `1.1.0` (never `v1.1.0`).
  final String version;

  /// The release page the user should be sent to.
  final String downloadUrl;

  /// Human title of the release, when GitHub provides one.
  final String? releaseName;
}

/// Collapses the shapes a release tag can take into `major.minor.patch`.
///
/// `v1.2.3`, `1.2.3+7`, `1.2.3-beta.1` and `1.2` all become `1.2.3`, `1.2.3`,
/// `1.2.3` and `1.2.0`. Returns null when there is no usable version in [raw].
String? normaliseVersion(String raw) {
  String value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('v') || value.startsWith('V')) {
    value = value.substring(1);
  }
  // Drop build metadata and pre-release suffixes: an update is still an update
  // whether or not the release is tagged as a beta.
  final int cut = value.indexOf(RegExp(r'[+\- ]'));
  if (cut >= 0) {
    value = value.substring(0, cut);
  }
  final List<String> parts = value.split('.');
  if (parts.isEmpty || parts.length > 3) return null;

  final List<int> numbers = <int>[];
  for (final String part in parts) {
    final int? number = int.tryParse(part);
    if (number == null || number < 0) return null;
    numbers.add(number);
  }
  while (numbers.length < 3) {
    numbers.add(0);
  }
  return numbers.join('.');
}

/// Negative when [a] is older than [b], zero when equal, positive when newer.
///
/// Numeric per part, so `1.10.0` is newer than `1.9.9` (a string comparison
/// would get that backwards).
int compareVersions(String a, String b) {
  final List<int> left = _parts(a);
  final List<int> right = _parts(b);
  for (int i = 0; i < 3; i++) {
    if (left[i] != right[i]) {
      return left[i] < right[i] ? -1 : 1;
    }
  }
  return 0;
}

List<int> _parts(String version) {
  final List<String> split = version.split('.');
  return <int>[
    for (int i = 0; i < 3; i++)
      i < split.length ? int.tryParse(split[i]) ?? 0 : 0,
  ];
}

/// Reads the body of GitHub's `/repos/:owner/:repo/releases/latest` response.
///
/// Returns null for anything that is not a strictly newer release the user can
/// act on: malformed JSON, a "Not Found" body when no release exists yet, or a
/// release that is the same as or older than [currentVersion].
AppUpdate? parseLatestRelease(String body, String currentVersion) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;

  final Object? tag = decoded['tag_name'];
  final Object? url = decoded['html_url'];
  if (tag is! String || url is! String || url.isEmpty) return null;

  final String? latest = normaliseVersion(tag);
  final String? current = normaliseVersion(currentVersion);
  if (latest == null || current == null) return null;
  if (compareVersions(latest, current) <= 0) return null;

  final Object? name = decoded['name'];
  return AppUpdate(
    version: latest,
    downloadUrl: url,
    releaseName: (name is String && name.trim().isNotEmpty) ? name.trim() : null,
  );
}
