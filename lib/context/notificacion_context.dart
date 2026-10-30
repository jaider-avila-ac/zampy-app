import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../services/api.dart';
import '../services/interaccion_service.dart';

// Equivalente a src/context/NotificacionContext.jsx en React
// Incluye WebSocket STOMP igual que React (@stomp/stompjs)

class NotificacionContext extends ChangeNotifier {
  int _unread = 0;
  Map<String, dynamic>? _suscripcionAlerta;
  int _suscripcionSeq = 0;
  int _notificacionSeq = 0;
  int _pedidosSeq = 0;
  String? _pedidosMenuCodigo;
  bool _websocketConectado = false;
  String? _websocketError;
  int _authExpiredSeq = 0;
  StompClient? _stomp;
  String? _connectedToken;

  int get unread => _unread;
  Map<String, dynamic>? get suscripcionAlerta => _suscripcionAlerta;
  int get suscripcionSeq => _suscripcionSeq;
  int get notificacionSeq => _notificacionSeq;
  int get pedidosSeq => _pedidosSeq;
  String? get pedidosMenuCodigo => _pedidosMenuCodigo;
  bool get websocketConectado => _websocketConectado;
  String? get websocketError => _websocketError;
  int get authExpiredSeq => _authExpiredSeq;

  void setUnread(int count) {
    if (_unread == count) return;
    _unread = count;
    notifyListeners();
  }

  void incrementUnread() {
    _unread++;
    notifyListeners();
  }

  void resetUnread() {
    if (_unread == 0) return;
    _unread = 0;
    notifyListeners();
  }

  void dismissAlerta() {
    _suscripcionAlerta = null;
    notifyListeners();
  }

  // Llamado al iniciar sesión — carga sinLeer y conecta WebSocket
  Future<void> onLogin(String token) async {
    if (_connectedToken == token) return;
    _connectedToken = token;

    // Cargar badge de no leídas igual que React (interaccionService.getSinLeer)
    try {
      final count = await InteraccionService.getSinLeer();
      if (_connectedToken == token) setUnread(count);
    } catch (_) {}

    _connectStomp(token);
  }

  // Llamado al cerrar sesión
  void onLogout() {
    _connectedToken = null;
    _unread = 0;
    _suscripcionAlerta = null;
    _pedidosMenuCodigo = null;
    _websocketConectado = false;
    _websocketError = null;
    _stomp?.deactivate();
    _stomp = null;
    notifyListeners();
  }

  void _connectStomp(String token) {
    _stomp?.deactivate();
    _websocketError = null;
    _websocketConectado = false;
    _stomp = StompClient(
      config: StompConfig(
        url: '$kWsBase/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onConnect,
        onStompError: _onStompError,
        onDisconnect: (_) => _setConnected(false),
        onWebSocketError: (error) {
          _setConnected(false, error: 'No se pudo conectar en tiempo real.');
        },
        onWebSocketDone: () => _setConnected(false),
      ),
    );
    _stomp!.activate();
  }

  void _setConnected(bool connected, {String? error}) {
    final nextError = connected ? null : (error ?? _websocketError);
    if (_websocketConectado == connected && _websocketError == nextError) {
      return;
    }
    _websocketConectado = connected;
    _websocketError = nextError;
    notifyListeners();
  }

  void _onConnect(StompFrame frame) {
    _setConnected(true);

    // Badge en tiempo real — igual que React: client.subscribe('/user/queue/notificaciones', ...)
    _stomp?.subscribe(
      destination: '/user/queue/notificaciones',
      callback: (_) {
        _notificacionSeq++;
        incrementUnread();
      },
    );

    // Alertas de suscripción (pago aprobado, vencido, etc.)
    _stomp?.subscribe(
      destination: '/user/queue/suscripcion',
      callback: (frame) {
        try {
          final data = jsonDecode(frame.body ?? '{}') as Map<String, dynamic>;
          _suscripcionAlerta = data;
          _suscripcionSeq++;
          notifyListeners();
        } catch (_) {}
      },
    );

    // Pedidos en tiempo real (admin/mesero/cliente según el evento)
    _stomp?.subscribe(
      destination: '/user/queue/pedidos',
      callback: (frame) {
        try {
          final data = jsonDecode(frame.body ?? '{}') as Map<String, dynamic>;
          final codigo = data['menuCodigo']?.toString();
          if (codigo != null && codigo.isNotEmpty) {
            _pedidosMenuCodigo = codigo;
          }
          _pedidosSeq++;
          notifyListeners();
        } catch (_) {
          _pedidosSeq++;
          notifyListeners();
        }
      },
    );
  }

  void _onStompError(StompFrame frame) {
    final detail = '${frame.headers['message'] ?? ''} ${frame.body ?? ''}';
    final authError = RegExp(
      r'AUTH_REQUIRED|TOKEN_INVALID|SESSION_EXPIRED|SESSION_INVALID',
      caseSensitive: false,
    ).hasMatch(detail);
    if (authError) {
      _authExpiredSeq++;
      _setConnected(false, error: 'Tu sesión expiró. Inicia sesión de nuevo.');
    } else {
      _setConnected(
        false,
        error: 'Error de conexión en tiempo real. Reintentando…',
      );
    }
    // No desconectamos: STOMP reintenta con reconnectDelay.
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    super.dispose();
  }
}
