/// Non-web: nothing to persist across reloads (the app isn't reloaded).
class SessionStore {
  SessionStore._();

  static String? read(String key) => null;
  static void write(String key, String value) {}
  static void remove(String key) {}
}
