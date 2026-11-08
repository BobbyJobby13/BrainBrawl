// Flutter puts one window in each process, so the player display is a second
// copy of the app. The two processes share state through a small JSON file,
// which only exists on desktop — a web build has no second window to drive, so
// the implementation is picked at compile time exactly like url_opener.dart.
export 'live_link_stub.dart' if (dart.library.io) 'live_link_io.dart';
