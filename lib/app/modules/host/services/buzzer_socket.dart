// Web builds use dart:html (browser WebSocket), desktop and mobile builds use
// dart:io. The stub only compiles where neither library exists.
export 'buzzer_socket_stub.dart'
    if (dart.library.html) 'buzzer_socket_web.dart'
    if (dart.library.io) 'buzzer_socket_io.dart';
