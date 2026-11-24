import 'dart:html' as html;

/// Web: `window.sessionStorage` — per tab, survives reloads.
class SessionStore {
  SessionStore._();

  static String? read(String key) {
    try {
      return html.window.sessionStorage[key];
    } catch (_) {
      return null; // storage blocked (private mode, policy) — just don't restore
    }
  }

  static void write(String key, String value) {
    try {
      html.window.sessionStorage[key] = value;
    } catch (_) {}
  }

  static void remove(String key) {
    try {
      html.window.sessionStorage.remove(key);
    } catch (_) {}
  }
}
