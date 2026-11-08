// Opening a link needs a browser on desktop and dart:html in a web build, so
// the implementation is chosen at compile time exactly like buzzer_socket.dart.
export 'url_opener_stub.dart'
    if (dart.library.html) 'url_opener_web.dart'
    if (dart.library.io) 'url_opener_io.dart';
