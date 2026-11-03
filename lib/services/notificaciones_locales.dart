import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Notificaciones del sistema (barra de estado). Se muestran cuando llega un aviso por WebSocket
/// y el usuario las tiene activadas en Ajustes. Mientras la app está en primer plano o viva en
/// segundo plano con el WebSocket conectado; para entrega con la app cerrada haría falta push (FCM).
class NotificacionesLocales {
  NotificacionesLocales._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _prefKey = 'notis_sistema';
  static const _canalId = 'zammpy_general';
  static const _canalNombre = 'Notificaciones';
  static const _canalDesc = 'Avisos de pedidos, suscripción y actividad';

  static bool _habilitadas = false;
  static bool _listo = false;

  static bool get habilitadas => _habilitadas;

  /// Al arrancar: inicializa el plugin, crea el canal y lee la preferencia guardada.
  static Future<void> init() async {
    try {
      _habilitadas = (await _storage.read(key: _prefKey)) == '1';
    } catch (_) {}
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _canalId, _canalNombre,
            description: _canalDesc,
            importance: Importance.high,
          ));
      _listo = true;
    } catch (_) {
      _listo = false;
    }
  }

  /// Activa (pidiendo permiso al sistema) o desactiva. Devuelve el estado final real.
  static Future<bool> establecer(bool habilitar) async {
    if (habilitar) {
      bool permitido = true;
      try {
        permitido = await _plugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            true;
      } catch (_) {
        permitido = false;
      }
      _habilitadas = permitido;
    } else {
      _habilitadas = false;
    }
    try {
      await _storage.write(key: _prefKey, value: _habilitadas ? '1' : '0');
    } catch (_) {}
    return _habilitadas;
  }

  /// Muestra un aviso en la barra de estado (si están activadas).
  static Future<void> mostrar({required String titulo, required String texto}) async {
    if (!_habilitadas || !_listo) return;
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId, _canalNombre,
        channelDescription: _canalDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    try {
      await _plugin.show(id, titulo.isEmpty ? 'Zammpy' : titulo,
          texto.isEmpty ? null : texto, detalles);
    } catch (_) {}
  }
}
