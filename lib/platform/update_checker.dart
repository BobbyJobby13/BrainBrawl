/// Update check for the packaged desktop app.
///
/// Only the `dart:io` targets (macOS and Windows builds) do any work; the web
/// build resolves [checkForAppUpdate] and [openDownloadPage] to no-ops so the
/// browser version never talks to the GitHub API.
export 'update_checker_stub.dart'
    if (dart.library.io) 'update_checker_io.dart';
