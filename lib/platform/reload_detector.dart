/// Browser-reload notifications, with a no-op stand-in on desktop and mobile.
///
/// The third-party detector imports `dart:html` unconditionally, which makes it
/// impossible to compile the desktop builds. This wrapper is the only place the
/// app touches it, and only the web branch imports the package.
export 'reload_detector_stub.dart'
    if (dart.library.html) 'reload_detector_web.dart';
