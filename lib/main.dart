import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'context/auth_context.dart';
import 'context/cart_context.dart';
import 'context/likes_context.dart';
import 'context/notificacion_context.dart';
import 'modules/explore/hooks/use_explore.dart';
import 'services/device_info_service.dart';
import 'services/notificaciones_locales.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Identidad del dispositivo para "Sesiones activas" (antes de cualquier login/refresh)
  await DeviceInfoService.init();
  // Notificaciones del sistema (lee la preferencia e inicializa el canal)
  await NotificacionesLocales.init();
  final auth = AuthContext();
  auth.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthContext>.value(value: auth),
        ChangeNotifierProvider(create: (_) => LikesContext()),
        ChangeNotifierProvider(create: (_) => NotificacionContext()),
        ChangeNotifierProvider(create: (_) => ExploreController()),
        ChangeNotifierProvider(create: (_) => CartContext()),
      ],
      child: _AuthWatcher(child: ZammpyApp(auth: auth)),
    ),
  );
}

// Conecta/desconecta el WebSocket STOMP cuando cambia el estado de autenticación.
// Equivalente al useEffect([user]) en NotificacionContext.jsx de React.
class _AuthWatcher extends StatefulWidget {
  const _AuthWatcher({required this.child});
  final Widget child;

  @override
  State<_AuthWatcher> createState() => _AuthWatcherState();
}

class _AuthWatcherState extends State<_AuthWatcher> {
  String? _lastToken;
  int _lastAuthExpiredSeq = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthContext>();
    final notif = context.watch<NotificacionContext>();
    final likes = context.read<LikesContext>();

    // Post-frame para no hacer side-effects durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      likes.updateFromAuth(auth);
      if (notif.authExpiredSeq != _lastAuthExpiredSeq) {
        _lastAuthExpiredSeq = notif.authExpiredSeq;
        if (auth.isLoggedIn) auth.forceLogout();
        return;
      }
      if (auth.isLoggedIn && auth.token != null && auth.token != _lastToken) {
        _lastToken = auth.token;
        notif.onLogin(auth.token!);
      } else if (!auth.isLoggedIn && _lastToken != null) {
        _lastToken = null;
        notif.onLogout();
        context.read<ExploreController>().onAuthChanged(isLoggedIn: false);
        context.read<CartContext>().reset();
      }
    });

    return widget.child;
  }
}
