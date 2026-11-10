/// Platform-conditional PDF download helper.
/// Resolves to the web implementation on Flutter Web, mobile/desktop otherwise.
export 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart'
    if (dart.library.io) 'pdf_downloader_mobile.dart';
