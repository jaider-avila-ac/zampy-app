import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'context/auth_context.dart';
import 'context/notificacion_context.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthContext()..init()),
        ChangeNotifierProvider(create: (_) => NotificacionContext()),
      ],
      child: const _AuthWatcher(child: ZammpyApp()),
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

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthContext>();
    final notif = context.read<NotificacionContext>();

    // Post-frame para no hacer side-effects durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (auth.isLoggedIn && auth.token != null && auth.token != _lastToken) {
        _lastToken = auth.token;
        notif.onLogin(auth.token!);
      } else if (!auth.isLoggedIn && _lastToken != null) {
        _lastToken = null;
        notif.onLogout();
      }
    });

    return widget.child;
  }
}
