/// The version of the running app, compared against the newest GitHub release.
///
/// There is no `package_info_plus` in this project, so the value is declared
/// here. `test/update_checker_test.dart` fails if this drifts from `version:` in
/// pubspec.yaml, so bump both together.
const String appVersion = '1.1.1';
