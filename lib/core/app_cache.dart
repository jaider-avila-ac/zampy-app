/// Cache en memoria para el patrón stale-while-revalidate.
/// Los datos se muestran al instante desde cache y se actualizan
/// silenciosamente en segundo plano sin vaciar la pantalla.
class AppCache {
  AppCache._();

  static final _store = <String, dynamic>{};

  static T? get<T>(String key) {
    final v = _store[key];
    return v is T ? v : null;
  }

  static void set(String key, dynamic value) => _store[key] = value;

  static void remove(String key) => _store.remove(key);

  /// Llama esto al cerrar sesión para que el próximo usuario empiece limpio.
  static void clear() => _store.clear();
}
