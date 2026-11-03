import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identidad del dispositivo para la lista de "Sesiones activas".
///
/// Manda dos cabeceras en cada petición (las usa el backend solo al abrir sesión):
///  - `X-Device-Id`:   UUID estable guardado una sola vez por instalación. Así el mismo teléfono
///                     es siempre el mismo dispositivo y no se acumula una sesión por cada login.
///  - `X-Device-Name`: etiqueta amable ("Redmi Note 11 · App Zammpy") para que el usuario reconozca
///                     el equipo. Antes la app salía como "Navegador" porque el backend guardaba el
///                     User-Agent crudo de Dart.
class DeviceInfoService {
  DeviceInfoService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _idKey = 'device_id';

  static String? _id;
  static String? _nombre;

  /// Calcula id y nombre una sola vez. Se llama al arrancar la app (main).
  static Future<void> init() async {
    _id ??= await _leerOCrearId();
    _nombre ??= await _nombreDispositivo();
  }

  /// Cabeceras para ApiClient. Si aún no se inicializó, va vacío (el backend lo tolera).
  ///
  /// IMPORTANTE: los valores de cabecera HTTP deben ser ASCII. Un modelo con acentos/símbolos
  /// (o el separador "·") haría que `package:http` lance y **toda** petición fallara (la app
  /// parecería "sin conexión"). Por eso se sanea a ASCII imprimible aquí.
  static Map<String, String> get headers {
    final h = <String, String>{};
    final id = _ascii(_id);
    final nombre = _ascii(_nombre);
    if (id.isNotEmpty) h['X-Device-Id'] = id;
    if (nombre.isNotEmpty) h['X-Device-Name'] = nombre;
    return h;
  }

  /// Deja solo ASCII imprimible (0x20–0x7E), colapsa espacios y recorta. Vacío si no queda nada.
  static String _ascii(String? v) {
    if (v == null) return '';
    return v
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String> _leerOCrearId() async {
    try {
      final existing = await _storage.read(key: _idKey);
      if (existing != null && existing.isNotEmpty) return existing;
      final r = Random.secure();
      final id = List.generate(32, (_) => '0123456789abcdef'[r.nextInt(16)]).join();
      await _storage.write(key: _idKey, value: id);
      return id;
    } catch (_) {
      return '';
    }
  }

  static Future<String> _nombreDispositivo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final modelo = _capitalizar(info.model.trim().isNotEmpty
            ? info.model.trim()
            : info.device.trim());
        final base = modelo.isNotEmpty ? modelo : 'Android';
        return '$base - App Zammpy';
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final modelo = info.utsname.machine.trim().isNotEmpty
            ? info.utsname.machine.trim()
            : (info.name.trim().isNotEmpty ? info.name.trim() : 'iPhone');
        return '$modelo - App Zammpy';
      }
    } catch (_) {
      // sin permisos o plugin no disponible → etiqueta genérica
    }
    return 'App Zammpy';
  }

  static String _capitalizar(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
