import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../modules/auth/auth_service.dart';

/// Equivalente a NotificacionContext.jsx — WebSocket STOMP + notificaciones locales.
///
/// • Conecta al endpoint ws://.../ws con el JWT del usuario.
/// • Suscribe a /user/queue/notificaciones → emite en [onNewNotification].
/// • Muestra una notificación del sistema cuando llega un mensaje
///   (incluso con la app en segundo plano).
/// • El canal se crea en [init] y el permiso se solicita ahí mismo.
///
/// Cuando la app está COMPLETAMENTE cerrada (killed), la conexión WS no existe.
/// Para ese caso se necesitaría FCM (Firebase Cloud Messaging).
class PushService {
  PushService._();

  static const _channelId   = 'zampy_notif';
  static const _channelName = 'ZamPy — Notificaciones';
  static const _channelDesc = 'Reseñas, calificaciones y actividad de tus menús';

  static final _flnp       = FlutterLocalNotificationsPlugin();
  static final _controller = StreamController<void>.broadcast();
  static StompClient? _client;
  static int _notifId = 0;

  /// Stream que emite cada vez que llega una notificación via WebSocket.
  /// ExploreScreen escucha esto para actualizar el contador sin-leer.
  static Stream<void> get onNewNotification => _controller.stream;

  // ── Init (llamar desde main() antes de runApp) ─────────────────────────────
  static Future<void> init() async {
    // Inicializar flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _flnp.initialize(
      const InitializationSettings(android: androidInit),
    );

    // Crear canal de notificación (Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _flnp
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Pedir permiso POST_NOTIFICATIONS (Android 13 / API 33+)
    await _flnp
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Conectar WebSocket STOMP ───────────────────────────────────────────────
  /// Llama esto después de que el usuario inicia sesión.
  static Future<void> connect() async {
    if (_client != null) return; // ya conectado
    final token = await AuthService.getToken();
    if (token == null) return;

    // Derivar URL WebSocket desde la API base (http→ws, https→wss)
    final wsUrl = kApiBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    _client = StompClient(
      config: StompConfig(
        url: '$wsUrl/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: _onConnected,
        onStompError: (_) {},
        onWebSocketError: (_) {},
        onDisconnect: (_) {},
      ),
    );
    _client!.activate();
  }

  static void _onConnected(StompFrame _) {
    _client?.subscribe(
      destination: '/user/queue/notificaciones',
      callback: (StompFrame frame) {
        // Notificar a la UI
        _controller.add(null);
        // Mostrar notificación del sistema
        _showSystemNotification(frame.body);
      },
    );
  }

  // ── Desconectar ────────────────────────────────────────────────────────────
  /// Llama esto al cerrar sesión.
  static void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  // ── Notificación del sistema ───────────────────────────────────────────────
  static Future<void> _showSystemNotification(String? body) async {
    _notifId = (_notifId + 1) % 100; // IDs rotatorios 0..99
    await _flnp.show(
      _notifId,
      'Nueva notificación — ZamPy',
      body?.isNotEmpty == true ? body : 'Tienes actividad en tu menú.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
