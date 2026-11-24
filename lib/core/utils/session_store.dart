/// Tiny per-tab key/value store that survives a page reload.
///
/// On the web this is `window.sessionStorage`: it lives as long as the browser
/// tab (including reloads and Chrome silently discarding/restoring a background
/// tab) and is NOT shared with other tabs — so two tabs can each stay on a
/// different farm. On mobile/desktop the app isn't reloaded from a URL, so a
/// no-op store is enough.
export 'session_store_stub.dart'
    if (dart.library.html) 'session_store_web.dart';
