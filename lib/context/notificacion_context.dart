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
  int                   _unread          = 0;
  Map<String, dynamic>? _suscripcionAlerta;
  int                   _suscripcionSeq  = 0;
  StompClient?          _stomp;
  String?               _connectedToken;

  int                   get unread            => _unread;
  Map<String, dynamic>? get suscripcionAlerta => _suscripcionAlerta;
  int                   get suscripcionSeq    => _suscripcionSeq;

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
    final count = await InteraccionService.getSinLeer();
    setUnread(count);

    _connectStomp(token);
  }

  // Llamado al cerrar sesión
  void onLogout() {
    _connectedToken = null;
    _unread = 0;
    _stomp?.deactivate();
    _stomp = null;
    notifyListeners();
  }

  void _connectStomp(String token) {
    _stomp?.deactivate();
    _stomp = StompClient(
      config: StompConfig(
        url:                     '$kWsBase/ws',
        stompConnectHeaders:     {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay:          const Duration(seconds: 5),
        onConnect:               _onConnect,
        onStompError:            _onStompError,
        onWebSocketError:        (_) {},
        onDisconnect:            (_) {},
      ),
    );
    _stomp!.activate();
  }

  void _onConnect(StompFrame frame) {
    // Badge en tiempo real — igual que React: client.subscribe('/user/queue/notificaciones', ...)
    _stomp?.subscribe(
      destination: '/user/queue/notificaciones',
      callback:    (_) => incrementUnread(),
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
  }

  void _onStompError(StompFrame frame) {
    // Error de autenticación STOMP — no desconectamos, STOMP reintentará con reconnectDelay
  }

  @override
  void dispose() {
    _stomp?.deactivate();
    super.dispose();
  }
}
