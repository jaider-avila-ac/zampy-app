// Cache en memoria — equivalente a useCache.js de React
// Stale-while-revalidate: muestra datos cacheados inmediatamente, revalida en background.
// Se limpia al matar la app (igual que React).

class _CacheEntry {
  final dynamic data;
  final bool    stale;
  const _CacheEntry(this.data, {this.stale = false});
}

class AppCache {
  static final _store = <String, _CacheEntry>{};

  // Devuelve datos frescos o null si no existen / están stale
  static dynamic get(String key) {
    final e = _store[key];
    if (e == null || e.stale) return null;
    return e.data;
  }

  // Devuelve datos aunque estén stale — para evitar pantallas vacías sin internet
  static dynamic getStale(String key) {
    return _store[key]?.data;
  }

  // Guarda datos frescos
  static void set(String key, dynamic data) {
    _store[key] = _CacheEntry(data);
  }

  // Marca como stale pero conserva los datos para mostrar mientras revalida
  static void markStale(String key) {
    final e = _store[key];
    if (e != null) _store[key] = _CacheEntry(e.data, stale: true);
  }

  // Elimina entrada completamente
  static void invalidate(String key) => _store.remove(key);

  static bool hasData(String key) {
    final e = _store[key];
    return e != null && !e.stale;
  }

  // True si existe CUALQUIER clave con ese prefijo sin estar stale
  static bool hasAnyData(String prefix) =>
      _store.keys.any((k) => k.startsWith(prefix) && !(_store[k]?.stale ?? true));

  // Borra SOLO datos del usuario autenticado — llamar en logout().
  // NO borra el feed del explorador (es data pública).
  static void clearUserData() {
    const userKeys = ['notifications', 'logros', 'invitaciones'];
    for (final k in userKeys) {
      _store.remove(k);
    }
  }
}
