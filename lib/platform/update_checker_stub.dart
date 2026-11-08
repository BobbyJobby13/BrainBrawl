import 'app_update.dart';

/// Web (and any non-`dart:io`) fallback: updates are a desktop concern, and the
/// browser build always loads the newest version from the server anyway.
Future<AppUpdate?> checkForAppUpdate(String currentVersion) async => null;

/// Nothing to open when there is no update to offer.
Future<bool> openDownloadPage(String url) async => false;
