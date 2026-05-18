export 'io_platform_stub.dart'
    if (dart.library.io) 'io_platform_io.dart'
    if (dart.library.html) 'io_platform_web.dart';
