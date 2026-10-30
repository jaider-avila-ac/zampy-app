class AuthRedirect {
  AuthRedirect._();

  static String? _pending;

  static void remember(String location) {
    if (location.isEmpty) return;
    if (location == '/login' || location.startsWith('/login?')) return;
    _pending = location;
  }

  static String? consume() {
    final value = _pending;
    _pending = null;
    return value;
  }

  static void clear() => _pending = null;
}
