/// Web-safe phrasing HTTP. Conditional so Flutter web never sees dart:io.
export 'phrase_http_stub.dart'
    if (dart.library.html) 'phrase_http_browser.dart'
    if (dart.library.io) 'phrase_http_io.dart';
